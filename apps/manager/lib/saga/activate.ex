defmodule Manager.Saga.Activate do
  use GenServer, restart: :transient

  alias AuctionHouse
  alias Manager.Impl.PriceAnalyst

  alias Shared.Data.{
    Order,
    PlacedOrder,
    Product,
    User
  }

  alias Store

  @type price :: pos_integer()

  @default_deps %{
    store: Store,
    auction_house: AuctionHouse
  }

  @non_patreon_order_limit 100

  ##########
  # Client #
  ##########

  def start_link(
        %{from: from, args: %{syndicates_with_strategy: _syndicates_with_strategy}} = state
      ) do
    updated_state =
      %{
        deps: Map.merge(@default_deps, Map.get(state, :deps, %{})),
        args: state.args,
        non_patreon_order_limit:
          Map.get(state, :non_patreon_order_limit, @non_patreon_order_limit),
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
          deps: %{store: store, auction_house: auction_house},
          non_patreon_order_limit: _limit,
          args: %{syndicates_with_strategy: syndicates_with_strategy},
          from: from
        } = state
      ) do
    with {:ok, {_auth, %User{} = user}} <- auction_house.get_saved_login(),
         :ok <- store.activate_syndicates(syndicates_with_strategy),
         :ok <- auction_house.get_user_orders(user.ingame_name) do
      updated_state = Map.put(state, :user, user)

      send(from, {:activate, :get_user_orders})
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
          args: %{syndicates_with_strategy: syndicates_with_strategy},
          non_patreon_order_limit: limit,
          user: %User{patreon?: patreon?},
          from: from
        } = state
      ) do
    with {:ok, total_products} <- syndicates_with_strategy |> Map.keys() |> store.list_products(),
         order_number_limit <-
           calculate_order_limit(placed_orders, total_products, limit, patreon?) do
      if order_number_limit == 0 do
        send(from, {:activate, :no_slots_free})
        {:stop, :normal, state}
      else
        product_prices =
          Enum.reduce(total_products, %{}, fn product, prices ->
            Map.put(prices, product, nil)
          end)

        updated_state =
          state
          |> Map.put(:total_products_count, length(total_products))
          |> Map.put(:product_prices, product_prices)
          |> Map.put(:order_number_limit, order_number_limit)

        product_prices
        |> Map.keys()
        |> Enum.map(& &1.name)
        |> Enum.each(&auction_house.get_item_orders/1)

        send(from, {:activate, :calculating_item_prices})
        {:noreply, updated_state}
      end
    end
  end

  def handle_info(
        {:get_item_orders, {tag, item_name, data}},
        %{
          deps: %{store: store, auction_house: _auction_house},
          args: %{syndicates_with_strategy: syndicates_with_strategy},
          product_prices: product_prices,
          total_products_count: total_products_count,
          non_patreon_order_limit: _limit,
          user: _user,
          order_number_limit: order_number_limit,
          from: from
        } = state
      ) do
    with {:ok, all_syndicates} <- store.list_syndicates(),
         {:ok, strategies} <- Manager.strategies() do
      syndicates =
        Enum.filter(all_syndicates, fn syndicate ->
          syndicate.id in Map.keys(syndicates_with_strategy)
        end)

      product =
        product_prices
        |> Map.keys()
        |> Enum.find(&(&1.name == item_name))

      owner_syndicate =
        Enum.find(syndicates, fn the_syndicate ->
          product.id in the_syndicate.catalog
        end)

      strategy_id = Map.get(syndicates_with_strategy, owner_syndicate.id)
      strategy = Enum.find(strategies, &(&1.id == strategy_id))

      updated_product_prices =
        case tag do
          :ok ->
            Map.put(
              product_prices,
              product,
              PriceAnalyst.calculate_price(product, data, strategy)
            )

          :error ->
            Map.put(
              product_prices,
              product,
              product.default_price
            )
        end

      updated_state = Map.put(state, :product_prices, updated_product_prices)

      calculated_prices_count =
        updated_product_prices
        |> Map.values()
        |> Enum.count(&(&1 != nil))

      all_prices_calculated? = calculated_prices_count == total_products_count

      send(
        from,
        {:activate,
         {:price_calculated, item_name, Map.get(updated_product_prices, product),
          calculated_prices_count, total_products_count}}
      )

      if all_prices_calculated? do
        send(self(), :all_prices_calculated)
      end

      {:noreply, updated_state}
    end
  end

  def handle_info(
        :all_prices_calculated,
        %{
          deps: %{store: _store, auction_house: auction_house},
          args: %{syndicates_with_strategy: _syndicates_with_strategy},
          product_prices: product_prices,
          non_patreon_order_limit: _limit,
          total_products_count: _total_products_count,
          user: _user,
          order_number_limit: order_number_limit,
          from: from
        } = state
      ) do
    orders_placed =
      product_prices
      |> Enum.to_list()
      |> Enum.sort(fn {_product_1, price_1}, {_product_2, price_2} ->
        price_1 >= price_2
      end)
      |> Enum.take(order_number_limit)
      |> Enum.reduce(%{}, fn {product, price}, acc ->
        Map.put(acc, {product, price}, nil)
      end)

    updated_state = Map.put(state, :orders_placed, orders_placed)

    orders_placed
    |> Map.keys()
    |> Enum.map(fn {product, price} -> build_order(product, price) end)
    |> Enum.each(&auction_house.place_order/1)

    send(from, {:activate, :placing_orders})

    {:noreply, updated_state}
  end

  # TODO: we we fail to place the order, we may want to retry / give up
  def handle_info(
        {:place_order, {:ok, placed_order}},
        %{
          deps: %{store: _store, auction_house: _auction_house},
          args: %{syndicates_with_strategy: _syndicates_with_strategy},
          product_prices: _product_prices,
          non_patreon_order_limit: _limit,
          user: _user,
          order_number_limit: order_number_limit,
          orders_placed: orders_placed,
          from: from
        } = state
      ) do
    product_price =
      orders_placed
      |> Map.keys()
      |> Enum.find(fn {product, _price} -> product.id == placed_order.item_id end)

    updated_orders_placed = Map.put(orders_placed, product_price, placed_order)
    updated_state = Map.put(state, :orders_placed, updated_orders_placed)

    placed_orders_count =
      updated_orders_placed
      |> Map.values()
      |> Enum.count(&(&1 != nil))

    all_orders_placed? =
      placed_orders_count ==
        updated_orders_placed |> Map.to_list() |> length()

    product = elem(product_price, 0)

    send(
      from,
      {:activate, {:order_placed, product.name, placed_orders_count, order_number_limit}}
    )

    if all_orders_placed? do
      send(from, {:activate, :done})

      {:stop, :normal, state}
    else
      {:noreply, updated_state}
    end
  end

  ###########
  # Private #
  ###########

  @spec calculate_order_limit([PlacedOrder.t()], [Product.t()], pos_integer(), boolean()) ::
          non_neg_integer()
  defp calculate_order_limit(placed_orders, total_products, max_limit, false) do
    available_slots = max_limit - length(placed_orders)
    min(length(total_products), available_slots)
  end

  defp calculate_order_limit(_placed_orders, total_products, _limit, true),
    do: length(total_products)

  @spec build_order(Product.t(), price()) :: Order.t()
  defp build_order(%Product{rank: "n/a"} = product, price),
    do:
      Order.new(%{
        "order_type" => "sell",
        "item_id" => product.id,
        "platinum" => price,
        "quantity" => product.quantity
      })

  defp build_order(%Product{} = product, price),
    do:
      Order.new(%{
        "order_type" => "sell",
        "item_id" => product.id,
        "platinum" => price,
        "quantity" => product.quantity,
        "mod_rank" => product.rank
      })
end
