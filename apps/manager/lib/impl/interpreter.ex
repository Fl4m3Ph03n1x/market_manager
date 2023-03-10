defmodule Manager.Impl.Interpreter do
  @moduledoc """
  Core of the manager, where all the logic and communication with outer
  layers is. Currently, it works more like a bridge between the different ports
  of the application and manages data between them.
  """

  alias AuctionHouse
  alias Manager.Impl.PriceAnalyst
  alias Manager.Type
  alias Shared.Data.{Credentials, Order, OrderInfo, Product}
  alias Store

  @type dependencies :: keyword(module())

  @default_deps [
    store: Store,
    auction_house: AuctionHouse
  ]

  ##########
  # Public #
  ##########

  @spec activate(Type.syndicate(), Type.strategy(), Type.handle(), dependencies) :: :ok
  def activate(
        syndicate,
        strategy,
        handle,
        [store: store, auction_house: _auction_house] = deps \\ @default_deps
      ) do
    with {:ok, products} <- store.list_products(syndicate),
         total_products <- length(products),
         indexed_products <- Enum.with_index(products) do
      Enum.each(
        indexed_products,
        fn {product, index} ->
          result = place_request(product, syndicate, strategy, deps)
          handle.({:activate, syndicate, {index + 1, total_products, result}})
        end
      )
    else
      error -> handle.({:activate, syndicate, error})
    end

    handle.({:activate, syndicate, :done})
  end

  @spec deactivate(Type.syndicate(), Type.handle(), dependencies()) :: :ok
  def deactivate(
        syndicate,
        handle,
        [store: store, auction_house: _auction_house] = deps \\ @default_deps
      ) do
    with {:ok, order_ids} <- store.list_orders(syndicate),
         total_orders <- length(order_ids),
         indexed_orders <- Enum.with_index(order_ids) do
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

  @spec login(Credentials.t(), keep_logged_in :: boolean, Type.handle(), dependencies()) :: :ok
  def login(credentials, keep_logged_in, handle, deps \\ @default_deps) do
    with {:ok, {authorization, user}} <- deps[:auction_house].login(credentials),
         :ok <- maybe_save_login_data(keep_logged_in, {authorization, user}, deps) do
      handle.({:login, credentials, :done})
    else
      error -> handle.({:login, credentials, error})
    end
  end

  ###########
  # Private #
  ###########

  @spec place_request(Product.t(), Type.syndicate(), Type.strategy(), dependencies) ::
          {:ok, Type.order_id()} | {:error, any}
  defp place_request(
         product,
         syndicate,
         strategy,
         store: store,
         auction_house: auction_house
       ) do
    with price <- calculate_product_price(product, strategy, auction_house),
         order <- build_order(product, price),
         {:ok, order_id} <- auction_house.place_order(order),
         :ok <- store.save_order(order_id, syndicate) do
      {:ok, order_id}
    end
  end

  @spec calculate_product_price(Product.t(), Type.strategy(), deps :: module) ::
          Product.t()
  defp calculate_product_price(product, strategy, auction_house_api),
    do:
      product.name
      |> auction_house_api.get_all_orders()
      |> calculate_price(strategy, product)

  @spec calculate_price(
          {:ok, [OrderInfo.t()]} | {:error, any, product_name :: String.t()},
          Type.strategy(),
          Product.t()
        ) :: non_neg_integer
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

  @spec delete_order(Type.order_id(), Type.syndicate(), dependencies()) ::
          {:ok, Type.order_id()} | {:error, atom, Type.order_id()}
  defp delete_order(order_id, syndicate, store: store, auction_house: auction_house) do
    with {:ok, _order_id} <- auction_house.delete_order(order_id),
         :ok <- store.delete_order(order_id, syndicate) do
      {:ok, order_id}
    else
      {:error, :order_non_existent, order_id} ->
        case store.delete_order(order_id, syndicate) do
          {:error, reason} -> {:error, reason, order_id}
          _result -> {:ok, order_id}
        end

      error ->
        error
    end
  end

  @spec maybe_save_login_data(
          keep_logged_in :: boolean,
          {Authorization.t(), User.t()},
          dependencies
        ) :: :ok | {:error, any}
  defp maybe_save_login_data(false, _data, _deps), do: :ok

  defp maybe_save_login_data(true, {auth, user}, deps),
    do: deps[:store].save_login_data(auth, user)
end
