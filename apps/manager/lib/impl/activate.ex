defmodule Manager.Impl.Activate do
  @moduledoc """

  """

  require Logger

  alias AuctionHouse
  alias Manager.Imp.Login
  alias Shared.Data.User
  alias Store

  @default_deps %{
    store: Store,
    auction_house: AuctionHouse
  }

  @non_patreon_order_limit 100

  ##########
  # Public #
  ##########

  def fetch_user_orders(syndicates, strategy, %{auction_house: auction_house} = deps \\ @default_deps) do
    with {:ok, %User{ingame_name: username} = user} <- Login.recover_login(deps) do
      auction_house.get_user_orders(username, %{user: user, strategy: strategy, syndicates: syndicates})
    end
  end

  def fetch_market_prices(
        {:ok, placed_orders},
        %{user: user, syndicates: syndicates, strategy: strat},
        [store: store, auction_house: auction_house] \\ @default_deps
      ) do
    # 1. Find out which items from placed_orders are already in synds we want to Activate
    # 2. Calculate prices only for those items whihc are not placed already
    # 3. Send create order for top prices
    order_number_limit = @non_patreon_order_limit - length(placed_orders)

    products_with_syndicate =
      Enum.flat_map(syndicates, fn syndicate ->
        syndicate
        |> store.list_products()
        |> Shared.Utils.Tuples.from_tagged_tuple()
        |> Enum.map(fn product -> {product, syndicate} end)
      end)

    products_with_syndicate
    |> Enum.with_index(fn {product, syndicate}, index ->
      {product, syndicate, index}
    end)
    |> Enum.each(fn {product, syndicate, index} ->
      auction_house.get_all_orders(product.name, %{
        user: user,
        strategy: strat,
        limit: order_number_limit,
        product: product,
        produc_syndicate: syndicate,
        operation: :gather_product_prices,
        operation_index: index,
        operation_size: length(products_with_syndicate)
      })
    end)
  end

  def create_orders(market_orders, %{
        user: user,
        strategy: strat,
        limit: order_number_limit,
        product: product,
        produc_syndicate: syndicate
      }) do
  end

  # defp do_activate(
  #        %User{ingame_name: username, patreon?: false},
  #        syndicates,
  #        strategy,
  #        handle,
  #        [store: store, auction_house: auction_house] = deps
  #      ) do
  #
  #   with {:ok, placed_orders} <-
  #          auction_house.get_user_orders(username),
  #        # {:ok, synchronized_orders} <-
  #        #   syncrhonize_orders(placed_orders, store),
  #        # order_number_limit <- @non_patreon_order_limit - length(synchronized_orders),
  #        order_number_limit <- @non_patreon_order_limit - length(placed_orders),
  #        products_with_syndicate <-
  #          Enum.flat_map(syndicates, fn syndicate ->
  #            syndicate
  #            |> store.list_products()
  #            |> Shared.Utils.Tuples.from_tagged_tuple()
  #            |> Enum.map(fn product -> {product, syndicate} end)
  #          end),
  #        top_products_with_prices <-
  #          products_with_syndicate
  #          |> Enum.map(fn {product, syndicate} ->
  #            {product, calculate_product_price(product, strategy, auction_house), syndicate}
  #          end)
  #          |> Enum.sort(fn {_product_1, price_1, _synd_1}, {_product_2, price_2, _synd_2} ->
  #            price_1 >= price_2
  #          end)
  #          |> Enum.take(order_number_limit),
  #        indexed_products <-
  #          Enum.with_index(top_products_with_prices, fn {product, price, syndicate}, index ->
  #            {product, price, syndicate, index}
  #          end) do
  #     Enum.each(
  #       indexed_products,
  #       fn {product, price, syndicate, index} ->
  #         total_products = length(indexed_products)
  #         IO.inspect("##{index} -> #{product.name}, #{price}")
  #
  #         result =
  #           create_order(product, syndicate, price, placed_orders, deps)
  #           |> IO.inspect(label: "#{index}")
  #
  #         handle.({:activate, syndicate, {index + 1, total_products, result}})
  #       end
  #     )
  #   else
  #     error -> handle.({:activate, syndicates, error})
  #   end
  #
  #   handle.({:activate, syndicates, :done})
  # end
  #
  # @spec calculate_product_price(Product.t(), Strategy.t(), deps :: module) :: pos_integer()
  # def calculate_product_price(product, strategy, auction_house_api),
  #   do:
  #     product.name
  #     |> auction_house_api.get_all_orders()
  #     |> calculate_price(strategy, product)
  #     |> IO.inspect(label: product.name)
  #
  # @spec calculate_price(
  #         {:ok, [OrderInfo.t()]} | {:error, any, product_name :: String.t()},
  #         Strategy.t(),
  #         Product.t()
  #       ) :: pos_integer()
  # defp calculate_price({:ok, all_orders}, strategy, product),
  #   do: PriceAnalyst.calculate_price(product, all_orders, strategy)
  #
  # defp calculate_price(_error, _strategy, product) do
  #   Logger.warning("Failed to calculate price for product. Returning default.")
  #   product.default_price
  # end
end
