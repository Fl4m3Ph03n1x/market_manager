defmodule Manager.Saga.Deactivate do
  @moduledoc """
  Creates a process that will be responsible for the entire deactivation flow.
  """

  use GenServer, restart: :transient

  alias AuctionHouse
  alias Manager.Runtime.SagaSupervisor
  alias Shared.Data.{Product, Syndicate, User}
  alias Store

  @default_deps %{
    store: Store,
    auction_house: AuctionHouse
  }

  ##########
  # Client #
  ##########

  def start_link(%{from: from, args: %{syndicate_ids: _syndicate_ids}} = state) do
    updated_state = %{
      deps: Map.merge(@default_deps, Map.get(state, :deps, %{})),
      args: state.args,
      from: from
    }

    GenServer.start_link(__MODULE__, updated_state)
  end

  #############
  # Callbacks #
  #############

  @impl GenServer
  def init(state), do: {:ok, state, {:continue, nil}}

  @impl GenServer
  def handle_continue(
        nil,
        %{
          deps: %{store: _store, auction_house: auction_house},
          args: %{syndicate_ids: _syndicate_ids},
          from: from
        } = state
      ) do
    case auction_house.get_saved_login() do
      {:ok, {_auth, %User{} = user}} ->
        auction_house.get_user_orders(user.slug)
        updated_state = Map.put(state, :user, user)

        send(from, {:deactivate, {:ok, :get_user_orders}})
        {:noreply, updated_state}

      err ->
        {:stop, err, state}
    end
  end

  @impl GenServer
  def handle_info(
        {:get_user_orders, {:ok, placed_orders}},
        %{
          deps: %{store: store, auction_house: auction_house},
          args: %{syndicate_ids: _syndicate_ids},
          user: _user,
          from: from
        } = state
      ) do
    with {:ok, active_syndicate_ids} <- get_active_syndicate_ids(store),
         {:ok, active_syndicate_product_ids} <- get_active_syndicate_product_ids(active_syndicate_ids, store) do
      # We delete all orders that belong to known syndicates because after this step is complete, we do a full
      # reactivation of the remaining syndicates (if they are still active).
      orders_to_delete =
        Enum.filter(placed_orders, fn placed_order -> placed_order.item_id in active_syndicate_product_ids end)

      orders_to_delete_tracker =
        orders_to_delete
        |> Enum.map(&{&1, nil})
        |> Map.new()

      updated_state = Map.put(state, :orders_to_delete_tracker, orders_to_delete_tracker)

      Enum.each(orders_to_delete, &auction_house.delete_order/1)
      send(from, {:deactivate, {:ok, :deleting_orders}})
      {:noreply, updated_state}
    end
  end

  def handle_info(
        {:delete_order, {:ok, placed_order}},
        %{
          deps: %{store: store, auction_house: _auction_house},
          args: %{syndicate_ids: syndicate_ids},
          user: _user,
          orders_to_delete_tracker: orders_to_delete_tracker,
          from: from
        } = state
      ) do
    with {:ok, product} <- store.get_product_by_id(placed_order.item_id) do
      updated_tracker = Map.put(orders_to_delete_tracker, placed_order, true)
      updated_state = Map.put(state, :orders_to_delete_tracker, updated_tracker)

      deleted_orders_count =
        updated_tracker
        |> Map.values()
        |> Enum.count(&(&1 != nil))

      orders_to_delete_count = orders_to_delete_tracker |> Map.to_list() |> length()
      all_orders_deleted? = deleted_orders_count == orders_to_delete_count

      send(
        from,
        {:deactivate, {:ok, {:order_deleted, product.name, deleted_orders_count, orders_to_delete_count}}}
      )

      if all_orders_deleted? do
        with :ok <- store.deactivate_syndicates(syndicate_ids),
             {:ok, updated_active_syndicates} <- store.list_active_syndicates() do
          if Enum.empty?(updated_active_syndicates) do
            send(from, {:deactivate, {:ok, :done}})
          else
            send(from, {:deactivate, {:ok, :reactivating_remaining_syndicates}})
            # reactivate syndicate with last strategy used
            SagaSupervisor.activate(updated_active_syndicates, from)
          end

          {:stop, :normal, state}
        end
      else
        {:noreply, updated_state}
      end
    end
  end

  @spec get_active_syndicate_ids(module()) :: {:ok, [Syndicate.id()]} | {:error, :file.posix() | Jason.DecodeError.t()}
  defp get_active_syndicate_ids(store) do
    case store.list_active_syndicates() do
      {:ok, syndicates} -> {:ok, Map.keys(syndicates)}
      error -> error
    end
  end

  @spec get_active_syndicate_product_ids([Syndicate.id()], module()) ::
          {:ok, [Product.id()]}
          | {:error, :file.posix() | Jason.DecodeError.t() | {:syndicate_not_found, [Syndicate.id()]}}
  defp get_active_syndicate_product_ids(syndicate_ids, store) do
    case store.list_products(syndicate_ids) do
      {:ok, products} -> {:ok, Enum.map(products, & &1.id)}
      error -> error
    end
  end
end
