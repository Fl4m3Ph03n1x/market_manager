defmodule Manager.Impl.Interpreter do
  @moduledoc """
  Core of the manager, where all the logic and communication with outer
  layers is. Currently, it works more like a bridge between the different ports
  of the application and manages data between them.
  """

  alias AuctionHouse
  alias Manager.Impl.PriceAnalyst
  alias Manager.Type

  alias Shared.Data.{
    Authorization,
    Credentials,
    Order,
    OrderInfo,
    PlacedOrder,
    Product,
    Strategy,
    Syndicate,
    User
  }

  alias Store

  @default_deps [
    store: Store,
    auction_house: AuctionHouse
  ]

  @non_patreon_order_limit 100

  ##########
  # Public #
  ##########

  @spec activate([Syndicate.t()], Strategy.t(), Type.handle(), Type.dependencies()) ::
          Type.activate_response()
  def activate(
        syndicates,
        strategy,
        handle,
        deps \\ @default_deps
      ) do
    # 1. check if user is not Patreon
    # 2. fetch current user sell orders
    # 3. syncrhonize manual and automatic placed orders
    # 4. calculate difference and find how many automatic orders I can place
    # 5. given the strategy, calculate the sell price for each item
    # 6. order previous list in descending order
    # 7. create sell orders for the top items until we reach the order limit

    with {:ok, user} <- recover_login(deps) do
      do_activate(
        user,
        syndicates,
        strategy,
        handle,
        deps
      )
    end

    # with {:ok, products} <- store.list_products(syndicate),
    #      {:ok, placed_orders} <- store.list_orders(syndicate),
    #      total_products <- length(products),
    #      indexed_products <- Enum.with_index(products) do
    #   Enum.each(
    #     indexed_products,
    #     fn {product, index} ->
    #       result = create_order(product, syndicate, strategy, placed_orders, deps)
    #       handle.({:activate, syndicate, {index + 1, total_products, result}})
    #     end
    #   )
    # else
    #   error -> handle.({:activate, syndicate, error})
    # end
    #
    # handle.({:activate, syndicate, :done})
  end

  defp do_activate(
         %User{patreon?: true},
         _syndicate,
         _strategy,
         _handle,
         [store: _store, auction_house: _auction_house] = _deps
       ) do
    throw("not implemented")
  end

  defp do_activate(
         %User{ingame_name: username, patreon?: false},
         syndicates,
         strategy,
         handle,
         [store: store, auction_house: auction_house] = deps
       ) do
    # 1. check if user is not Patreon
    # 2. fetch current user sell orders
    # 3. syncrhonize manual and automatic placed orders
    # 4. calculate difference and find how many automatic orders I can place
    # 5. given the strategy, calculate the sell price for each item of all syndicates
    # 6. order previous list in descending order
    # 7. create sell orders for the top items until we reach the order limit
    with {:ok, placed_orders} <-
           auction_house.get_user_orders(username),
         # {:ok, synchronized_orders} <-
         #   syncrhonize_orders(placed_orders, store),
         # order_number_limit <- @non_patreon_order_limit - length(synchronized_orders),
         order_number_limit <- @non_patreon_order_limit - length(placed_orders),
         products_with_syndicate <-
           Enum.flat_map(syndicates, fn syndicate ->
             syndicate
             |> store.list_products()
             |> Shared.Utils.Tuples.from_tagged_tuple()
             |> Enum.map(fn product -> {product, syndicate} end)
           end),
         top_products_with_prices <-
           products_with_syndicate
           |> Enum.map(fn {product, syndicate} ->
             {product, calculate_product_price(product, strategy, auction_house), syndicate}
           end)
           |> Enum.sort(fn {_product_1, price_1, _synd_1}, {_product_2, price_2, _synd_2} ->
             price_1 >= price_2
           end)
           |> Enum.take(order_number_limit),
         indexed_products <-
           Enum.with_index(top_products_with_prices, fn {product, price, syndicate}, index ->
             {product, price, syndicate, index}
           end) do
      Enum.each(
        indexed_products,
        fn {product, price, syndicate, index} ->
          total_products = length(indexed_products)
          IO.inspect("##{index} -> #{product.name}, #{price}")

          result =
            create_order(product, syndicate, price, placed_orders, deps)
            |> IO.inspect(label: "#{index}")

          handle.({:activate, syndicate, {index + 1, total_products, result}})
        end
      )
    else
      error -> handle.({:activate, syndicates, error})
    end

    handle.({:activate, syndicates, :done})
  end

  # @spec syncrhonize_orders([PlacedOrder.t()], store :: module()) ::
  #         {:ok, [PlacedOrder.t()]} | {:error, any()}
  # defp syncrhonize_orders([], store) do
  #   case store.reset_orders() do
  #     :ok -> {:ok, []}
  #     err -> err
  #   end
  # end
  #
  # defp syncrhonize_orders(user_orders, store) do
  #   with {:ok, %{manual: manual_orders, automatic: auto_orders}} <- store.list_sell_orders(),
  #        all_orders <- manual_orders ++ auto_orders,
  #        user_missing_orders <- user_orders -- all_orders,
  #        user_deleted_orders <- manual_orders -- user_orders,
  #        nil <-
  #          user_missing_orders
  #          |> Enum.uniq()
  #          |> Enum.map(fn order -> store.save_order(order, nil) end)
  #          |> Enum.find(fn result -> result != :ok end),
  #        nil <-
  #          user_deleted_orders
  #          |> Enum.uniq()
  #          |> Enum.map(fn order -> store.delete_order(order, nil) end)
  #          |> Enum.find(fn result -> result != :ok end),
  #        {:ok, %{manual: updated_manual_orders, automatic: updated_auto_orders}} <-
  #          store.list_sell_orders() do
  #     {:ok, updated_manual_orders ++ updated_auto_orders}
  #   end
  # end

  # TODO:  remake this to work with new activate()
  @spec deactivate(Syndicate.t(), Type.handle(), Type.dependencies()) ::
          Type.deactivate_response()
  def deactivate(
        syndicate,
        handle,
        [store: store, auction_house: _auction_house] = deps \\ @default_deps
      ) do
    with {:ok, placed_orders} <- store.list_sell_orders(),
         total_orders <- length(placed_orders),
         indexed_orders <- Enum.with_index(placed_orders) do
      Enum.each(
        indexed_orders,
        fn {order, index} ->
          result = delete_order(order, syndicate, deps)
          handle.({:deactivate, syndicate, {index + 1, total_orders, result}})
        end
      )
    else
      error -> handle.({:deactivate, syndicate, error})
    end

    handle.({:deactivate, syndicate, :done})
  end

  @spec login(Credentials.t(), keep_logged_in :: boolean, Type.handle(), Type.dependencies()) ::
          Type.login_response()
  def login(credentials, keep_logged_in, handle, deps \\ @default_deps) do
    case manual_login(credentials, keep_logged_in, deps) do
      {:ok, user} -> handle.({:login, user, :done})
      error -> handle.({:login, credentials, error})
    end
  end

  @spec recover_login(Type.dependencies()) :: Type.recover_login_response()
  def recover_login(deps \\ @default_deps), do: automatic_login(deps)

  @spec logout(Type.dependencies()) :: Type.logout_response()
  def logout([store: store, auction_house: auction_house] \\ @default_deps) do
    with :ok <- auction_house.logout() do
      store.delete_login_data()
    end
  end

  @spec syndicates(Type.dependencies()) :: Type.syndicates_response()
  def syndicates([store: store, auction_house: _auction_house] \\ @default_deps),
    do: store.list_syndicates()

  @spec active_syndicates(Type.dependencies()) :: Type.active_syndicates_response()
  def active_syndicates([store: store, auction_house: _auction_house] \\ @default_deps),
    do: store.list_active_syndicates()

  @spec strategies :: Type.strategies_response()
  def strategies, do: PriceAnalyst.list_strategies()

  ###########
  # Private #
  ###########

  @spec create_order(
          Product.t(),
          Syndicate.t(),
          pos_integer(),
          [PlacedOrder.t()],
          Type.dependencies()
        ) ::
          {:ok, PlacedOrder.t()} | {:error, any}
  defp create_order(
         product,
         syndicate,
         price,
         placed_orders,
         store: store,
         auction_house: auction_house
       ) do
    already_placed_order =
      Enum.find(placed_orders, fn %PlacedOrder{item_id: id} -> id == product.id end)

    if is_nil(already_placed_order) do
      with order <- build_order(product, price),
           {:ok, placed_order} <- auction_house.place_order(order) do
        # :ok <- store.save_order(placed_order, syndicate.id) do
        {:ok, placed_order}
      end
    else
      {:ok, already_placed_order}
    end
  end

  @spec calculate_product_price(Product.t(), Strategy.t(), deps :: module) :: pos_integer()
  def calculate_product_price(product, strategy, auction_house_api),
    do:
      product.name
      |> auction_house_api.get_all_orders()
      |> calculate_price(strategy, product)
      |> IO.inspect(label: product.name)

  @spec calculate_price(
          {:ok, [OrderInfo.t()]} | {:error, any, product_name :: String.t()},
          Strategy.t(),
          Product.t()
        ) :: pos_integer()
  defp calculate_price({:ok, all_orders}, strategy, product),
    do: PriceAnalyst.calculate_price(product, all_orders, strategy)

  defp calculate_price(_error, _strategy, product) do
    require Logger
    Logger.warning("Failed to calculate price for product. Returning default.")
    product.default_price
  end

  @spec build_order(Product.t(), price :: pos_integer) :: Order.t()
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

  @spec delete_order(PlacedOrder.t(), Syndicate.t(), Type.dependencies()) ::
          {:ok, PlacedOrder.t()} | {:error, atom, PlacedOrder.t()}
  defp delete_order(placed_order, syndicate, store: store, auction_house: auction_house) do
    with :ok <- auction_house.delete_order(placed_order),
         :ok <- store.delete_order(placed_order, syndicate) do
      {:ok, placed_order}
    else
      # placed_order is in storage, but not in market.
      # This means we deleted the order from the market manually and did not
      # use the manager to do it, even though we did place the order using the
      # manger. We simply try to update Storage by removing the placed_order.
      {:error, :order_non_existent, placed_order} ->
        case store.delete_order(placed_order, syndicate.id) do
          {:error, reason} -> {:error, reason, placed_order}
          _result -> {:ok, placed_order}
        end

      error ->
        error
    end
  end

  @spec automatic_login(Type.dependencies()) :: :ok | {:ok, nil} | {:error, any}
  defp automatic_login(store: store, auction_house: auction_house) do
    with {:ok, {auth, user}} <- store.get_login_data(),
         :ok <- auction_house.recover_login(auth, user) do
      {:ok, user}
    end
  end

  @spec manual_login(Credentials.t(), keep_logged_in :: boolean, Type.dependencies()) ::
          {:ok, User.t()} | {:error, any}
  defp manual_login(credentials, keep_logged_in,
         store: store,
         auction_house: auction_house
       ) do
    with {:ok, {_auth, user} = login_data} <- auction_house.login(credentials),
         :ok <- update_login_data(keep_logged_in, login_data, store) do
      {:ok, user}
    end
  end

  @spec update_login_data(
          keep_logged_in :: boolean,
          {Authorization.t(), User.t()},
          store :: module
        ) :: :ok | {:error, any}
  defp update_login_data(false, _data, store),
    do: store.delete_login_data()

  defp update_login_data(true, {auth, user}, store),
    do: store.save_login_data(auth, user)
end
