defmodule Manager.Saga.Activate do
  @moduledoc """
  Creates a process that will be responsible for the entire activation flow.
  """

  use GenServer, restart: :transient

  alias AuctionHouse
  alias Manager.Impl.PriceAnalyst

  alias Shared.Data.{
    PlacedOrder,
    User
  }

  alias Shared.Data.Product
  alias Store

  @type price :: pos_integer()

  @default_deps %{
    store: Store,
    auction_house: AuctionHouse
  }

  @non_patreon_order_limit Application.compile_env!(:manager, :non_patreon_order_limit)

  ##########
  # Client #
  ##########

  def start_link(%{from: from, args: %{syndicates_with_strategy: _syndicates_with_strategy}} = state) do
    updated_state =
      %{
        deps: Map.merge(@default_deps, Map.get(state, :deps, %{})),
        args: state.args,
        non_patreon_order_limit: Map.get(state, :non_patreon_order_limit, @non_patreon_order_limit),
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
         :ok <- auction_house.get_user_orders(user.slug) do
      updated_state = Map.put(state, :user, user)

      send(from, {:activate, {:ok, :get_user_orders}})
      {:noreply, updated_state}
    else
      err ->
        send(from, {:activate, {:error, {:continue, err}}})
        {:stop, err, state}
    end
  end

  @impl GenServer
  def handle_info(
        {:get_user_orders, {:ok, placed_orders}},
        %{
          deps: %{store: store, auction_house: _auction_house},
          args: %{syndicates_with_strategy: syndicates_with_strategy},
          non_patreon_order_limit: limit,
          user: %User{patreon?: patreon?},
          from: from
        } = state
      ) do
    with {:ok, total_products} <- list_relevant_products(syndicates_with_strategy, store),
         order_number_limit = calculate_order_limit(placed_orders, total_products, limit, patreon?),
         {:ok, updated_state} <- process_products(order_number_limit, total_products, state) do
      send(from, {:activate, {:ok, :calculating_item_prices}})
      {:noreply, updated_state}
    else
      {:error, :no_slots_free} ->
        send(from, {:activate, {:ok, :no_slots_free}})
        {:stop, :normal, state}

      {:error, {:failed_rollback_activation, err}} ->
        send(from, {:activate, {:error, {:failed_rollback_activation, err}}})
        {:stop, err, state}

      err ->
        send(from, {:activate, {:error, {:get_item_orders, err}}})
        {:stop, err, state}
    end
  end

  # if we cannot get user orders, there is no point in continuing
  def handle_info({:get_user_orders, {:error, _reason}} = error, %{from: from} = state) do
    send(from, {:activate, {:error, error}})
    {:stop, error, state}
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
          order_number_limit: _order_number_limit,
          from: from
        } = state
      ) do
    with {:ok, all_syndicates} <- store.list_syndicates() do
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

      updated_product_prices =
        case tag do
          :ok ->
            Map.put(
              product_prices,
              product,
              PriceAnalyst.calculate_price(product, data, strategy_id)
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
         {:ok,
          {:price_calculated, item_name, Map.get(updated_product_prices, product), calculated_prices_count,
           total_products_count}}}
      )

      if all_prices_calculated? do
        send(self(), :all_prices_calculated)
      end

      {:noreply, updated_state}
    end
  end

  # if we miss on a item order list, we can still continue
  # the price will remain nil and be filtered later on
  def handle_info({:get_item_orders, {:error, _reason}} = error, %{from: from} = state) do
    send(from, {:activate, {:error, error}})
    {:noreply, state}
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
      |> Enum.uniq_by(fn {product, _price} -> product.id end)
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
    |> Enum.filter(fn {_product, price} -> not is_nil(price) end)
    |> Enum.map(fn {product, price} -> Product.to_sell_order!(product, price) end)
    |> Enum.each(&auction_house.place_order/1)

    send(from, {:activate, {:ok, :placing_orders}})

    {:noreply, updated_state}
  end

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
      {:activate, {:ok, {:order_placed, product.name, placed_orders_count, order_number_limit}}}
    )

    if all_orders_placed? do
      send(from, {:activate, {:ok, :done}})

      {:stop, :normal, state}
    else
      {:noreply, updated_state}
    end
  end

  # if we fail to place an order, we can still continue with the others
  def handle_info({:place_order, {:error, _msg}} = error, %{from: from} = state) do
    send(from, {:activate, {:error, error}})
    {:noreply, state}
  end

  ###########
  # Private #
  ###########

  @spec list_relevant_products(map(), module()) :: Store.Type.list_products_response()
  defp list_relevant_products(syndicates_with_strategy, store) do
    syndicates_with_strategy
    |> Map.keys()
    |> store.list_products()
  end

  @spec process_products(
          non_neg_integer(),
          [Product.t()],
          %{
            deps: %{
              store: module(),
              auction_house: module()
            },
            args: %{
              syndicates_with_strategy: map()
            },
            from: pid(),
            non_patreon_order_limit: pos_integer(),
            user: User.t()
          }
        ) ::
          {:ok, map()}
          | {:error, :no_slots_free}
          | {:error, {:failed_rollback_activation, Store.Type.deactivate_syndicates_response()}}
  defp process_products(0, _total_products, %{
         deps: %{store: store},
         args: %{syndicates_with_strategy: syndicates_with_strategy}
       }) do
    case store.deactivate_syndicates(Map.keys(syndicates_with_strategy)) do
      :ok ->
        {:error, :no_slots_free}

      {:error, _reason} = err ->
        {:error, {:failed_rollback_activation, err}}
    end
  end

  defp process_products(order_number_limit, total_products, %{deps: %{auction_house: auction_house}} = state) do
    product_prices = initiate_product_prices(total_products)

    updated_state =
      state
      |> Map.put(:total_products_count, length(total_products))
      |> Map.put(:product_prices, product_prices)
      |> Map.put(:order_number_limit, order_number_limit)

    product_prices
    |> Map.keys()
    |> Enum.map(& &1.name)
    |> Enum.each(&auction_house.get_item_orders/1)

    {:ok, updated_state}
  end

  @spec initiate_product_prices([Product.t()]) :: %{Product.t() => nil}
  defp initiate_product_prices(total_products) do
    Enum.reduce(total_products, %{}, fn product, prices ->
      Map.put(prices, product, nil)
    end)
  end

  @spec calculate_order_limit([PlacedOrder.t()], [Product.t()], pos_integer(), boolean()) ::
          non_neg_integer()
  defp calculate_order_limit(placed_orders, total_products, max_limit, false) do
    available_slots = max_limit - length(placed_orders)
    min(length(total_products), available_slots)
  end

  defp calculate_order_limit(_placed_orders, total_products, _limit, true),
    do: length(total_products)
end
