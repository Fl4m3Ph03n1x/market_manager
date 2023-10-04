defmodule Manager.Impl.Interpreter do
  @moduledoc """
  Core of the manager, where all the logic and communication with outer
  layers is. Currently, it works more like a bridge between the different ports
  of the application and manages data between them.
  """

  alias AuctionHouse
  alias Manager.Impl.PriceAnalyst
  alias Manager.Type
  alias Shared.Data.{Credentials, Order, OrderInfo, PlacedOrder, Product, Strategy, Syndicate, User}
  alias Store

  @default_deps [
    store: Store,
    auction_house: AuctionHouse
  ]

  ##########
  # Public #
  ##########

  @spec activate(Syndicate.t(), Strategy.t(), Type.handle(), Type.dependencies()) :: Type.activate_response()
  def activate(
        syndicate,
        strategy,
        handle,
        [store: store, auction_house: _auction_house] = deps \\ @default_deps
      ) do
    with {:ok, products} <- store.list_products(syndicate),
         {:ok, placed_orders} <- store.list_orders(syndicate),
         total_products <- length(products),
         indexed_products <- Enum.with_index(products) do
      Enum.each(
        indexed_products,
        fn {product, index} ->
          result = create_order(product, syndicate, strategy, placed_orders, deps)
          handle.({:activate, syndicate, {index + 1, total_products, result}})
        end
      )
    else
      error -> handle.({:activate, syndicate, error})
    end

    handle.({:activate, syndicate, :done})
  end

  @spec deactivate(Syndicate.t(), Type.handle(), Type.dependencies()) :: Type.deactivate_response()
  def deactivate(
        syndicate,
        handle,
        [store: store, auction_house: _auction_house] = deps \\ @default_deps
      ) do
    with {:ok, placed_orders} <- store.list_orders(syndicate),
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

  @spec login(Credentials.t(), keep_logged_in :: boolean, Type.handle(), Type.dependencies()) :: Type.login_response()
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
    with  :ok <- auction_house.logout() do
      store.delete_login_data()
    end
  end

  @spec syndicates(Type.dependencies()) :: Type.syndicates_response()
  def syndicates([store: store, auction_house: _auction_house] \\ @default_deps), do: store.list_syndicates()

  @spec strategies :: Type.strategies_response()
  def strategies, do: PriceAnalyst.list_strategies()

  ###########
  # Private #
  ###########

  @spec create_order(
          Product.t(),
          Syndicate.t(),
          Strategy.t(),
          [PlacedOrder.t()],
          Type.dependencies()
        ) ::
          {:ok, PlacedOrder.t()} | {:error, any}
  defp create_order(
         product,
         syndicate,
         strategy,
         placed_orders,
         store: store,
         auction_house: auction_house
       ) do
    already_placed_order =
      Enum.find(placed_orders, fn %PlacedOrder{item_id: id} -> id == product.id end)

    if is_nil(already_placed_order) do
      with price <- calculate_product_price(product, strategy, auction_house),
           order <- build_order(product, price),
           {:ok, placed_order} <- auction_house.place_order(order),
           :ok <- store.save_order(placed_order, syndicate) do
        {:ok, placed_order}
      end
    else
      {:ok, already_placed_order}
    end
  end

  @spec calculate_product_price(Product.t(), Strategy.t(), deps :: module) :: pos_integer()
  defp calculate_product_price(product, strategy, auction_house_api),
    do:
      product.name
      |> auction_house_api.get_all_orders()
      |> calculate_price(strategy, product)

  @spec calculate_price(
          {:ok, [OrderInfo.t()]} | {:error, any, product_name :: String.t()},
          Strategy.t(),
          Product.t()
        ) :: pos_integer()
  defp calculate_price({:ok, all_orders}, strategy, product),
    do: PriceAnalyst.calculate_price(product, all_orders, strategy)

  defp calculate_price(_error, _strategy, product), do: product.default_price

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
        case store.delete_order(placed_order, syndicate) do
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
      :ok <-  update_login_data(keep_logged_in, login_data, store) do
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
