defmodule Manager.Saga.Deactivate do
  use GenServer, restart: :transient

  alias AuctionHouse
  alias Shared.Data.User
  alias Store

  @default_deps %{
    store: Store,
    auction_house: AuctionHouse
  }

  ##########
  # Client #
  ##########

  def start_link(%{from: from, args: %{syndicates: _syndicates}} = state) do
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
          args: %{syndicates: _syndicates},
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
          deps: %{store: store, auction_house: auction_house},
          args: %{syndicates: syndicates},
          user: _user,
          from: from
        } = state
      ) do
    # 1. Get active syndicates
    # 2. check which syndicates we want to deactivate. We remove a placed order if:
    #   - if belongs to one of the syndicates that we want to remove
    #   - if it belongs to one and ONLY one syndicate currently active. If it belongs to more than 1, we do nothing.
    # 3. We send requests to delete selected orders

    with {:ok, all_syndicates} <- store.list_syndicates(),
         {:ok, active_syndicates} <- store.list_active_syndicates() do
      product_ids_full_catalog =
        all_syndicates
        |> Enum.map(fn syndicate ->
          syndicate.catalog
          |> Enum.intersperse(syndicate.id)
          |> Enum.concat([syndicate.id])
          |> Enum.chunk_every(2)
          |> Enum.map(fn [k, v] -> {k, [v]} end)
          |> Map.new()
        end)
        |> Enum.reduce(%{}, fn product_ids, acc ->
          Map.merge(acc, product_ids, fn _item_id, v1, v2 -> Enum.concat(v1, v2) end)
        end)

      active_syndicate_ids =
        active_syndicates
        |> Enum.map(& &1.id)
        |> MapSet.new()

      orders_to_delete =
        placed_orders
        |> Enum.filter(fn placed_order ->
          syndicates_from_current_placed_order =
            product_ids_full_catalog
            |> Map.get(placed_order.item_id, [])
            |> MapSet.new()

          syndicates_from_current_placed_order
          |> MapSet.intersection(active_syndicate_ids)
          |> MapSet.size() == 1
        end)
        |> Enum.filter(fn current_placed_order ->
          deletable_items =
            syndicates
            |> Enum.flat_map(& &1.catalog)
            |> MapSet.new()

          MapSet.member?(deletable_items, current_placed_order.item_id)
        end)

      orders_to_delete_tracker =
        orders_to_delete
        |> Enum.map(&{&1, nil})
        |> Map.new()

      updated_state = Map.put(state, :orders_to_delete_tracker, orders_to_delete_tracker)

      Enum.each(orders_to_delete, &auction_house.delete_order/1)
      send(from, {:deactivate, :deleting_orders})
      {:noreply, updated_state}
    end
  end

  # TODO: if we fail to delete the order, we may want to retry / give up
  def handle_info(
        {:delete_order, {:ok, placed_order}},
        %{
          deps: %{store: store, auction_house: _auction_house},
          args: %{syndicates: syndicates},
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
        {:deactivate, {:order_deleted, product.name, deleted_orders_count, orders_to_delete_count}}
      )

      if all_orders_deleted? do
        with {:ok, active_syndicates} <- store.list_active_syndicates(),
             updated_active_syndicates <- active_syndicates -- syndicates,
             :ok <- store.set_active_syndicates(updated_active_syndicates) do
          if Enum.empty?(updated_active_syndicates) do
            send(from, {:deactivate, :done})
          else
            send(from, {:deactivate, :reactivating_remaining_syndicates})
            # reactivate syndicate with last strategy used
          end

          {:stop, :normal, state}
        end
      else
        {:noreply, updated_state}
      end
    end
  end
end
