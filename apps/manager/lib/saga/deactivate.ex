defmodule Manager.Saga.Deactivate do
  use GenServer, restart: :transient

  alias AuctionHouse
  alias Manager.Runtime.SagaSupervisor
  alias Shared.Data.User
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
    with {:ok, {_auth, %User{} = user}} <- auction_house.get_saved_login() do
      auction_house.get_user_orders(user.ingame_name)
      updated_state = Map.put(state, :user, user)

      send(from, {:deactivate, :get_user_orders})
      {:noreply, updated_state}
    else
      err ->
        {:stop, err, state}
    end
  end

  @impl GenServer
  def handle_info(
        {:get_user_orders, {:ok, placed_orders}},
        %{
          deps: %{store: _store, auction_house: auction_house},
          args: %{syndicate_ids: _syndicate_ids},
          user: _user,
          from: from
        } = state
      ) do
    # We delete all orders because after this step is complete, we do a full reactivation of the remaining syndicates.
    orders_to_delete_tracker =
      placed_orders
      |> Enum.map(&{&1, nil})
      |> Map.new()

    updated_state = Map.put(state, :orders_to_delete_tracker, orders_to_delete_tracker)

    Enum.each(placed_orders, &auction_house.delete_order/1)
    send(from, {:deactivate, :deleting_orders})
    {:noreply, updated_state}
  end

  # TODO: if we fail to delete the order, we may want to retry / give up
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
        {:deactivate,
         {:order_deleted, product.name, deleted_orders_count, orders_to_delete_count}}
      )

      if all_orders_deleted? do
        with :ok <- store.deactivate_syndicates(syndicate_ids),
             {:ok, updated_active_syndicates} <- store.list_active_syndicates() do
          if Enum.empty?(updated_active_syndicates) do
            send(from, {:deactivate, :done})
          else
            send(from, {:deactivate, :reactivating_remaining_syndicates})
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
end
