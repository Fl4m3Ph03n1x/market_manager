defmodule Manager.Impl.PriceAnalyst do
  @moduledoc """
  Contains the formulas and calculations for all the strategies.
  Strategies calculate the optimum price for you to sell an item.
  There are several strategies, some focus more on selling fast, while others
  on getting more profit.
  """

  alias Shared.Data.{OrderInfo, Product, Strategy}

  ##########
  # Public #
  ##########

  @spec calculate_price(Product.t(), [OrderInfo.t()], Strategy.t()) :: pos_integer()
  def calculate_price(product, all_orders, strategy),
    do:
      all_orders
      |> pre_process_orders()
      |> apply_strategy(strategy)
      |> apply_boundaries(product)

  ###########
  # Private #
  ###########

  defp pre_process_orders(all_orders),
    do:
      all_orders
      |> Enum.filter(&valid_order?/1)
      |> Enum.sort(&price_ascending/2)

  @spec valid_order?(OrderInfo.t()) :: boolean
  defp valid_order?(order),
    do: visible?(order) and user_ingame?(order) and platform_pc?(order) and sell_order?(order)

  @spec visible?(OrderInfo.t()) :: boolean
  defp visible?(order), do: order.visible == true

  @spec user_ingame?(OrderInfo.t()) :: boolean
  defp user_ingame?(order), do: order.user.status == "ingame"

  @spec platform_pc?(OrderInfo.t()) :: boolean
  defp platform_pc?(order), do: order.platform == "pc"

  @spec sell_order?(OrderInfo.t()) :: boolean
  defp sell_order?(order), do: order.order_type == "sell"

  @spec price_ascending(OrderInfo.t(), OrderInfo.t()) :: boolean
  defp price_ascending(order1, order2), do: order1.platinum < order2.platinum

  @spec apply_strategy([OrderInfo.t()], Strategy.t()) :: integer
  defp apply_strategy([], _strategy), do: 0

  defp apply_strategy([%OrderInfo{platinum: price}], _strategy), do: price

  defp apply_strategy(orders, %Strategy{id: :top_five_average}),
    do:
      orders
      |> Enum.take(5)
      |> Enum.map(&platinum/1)
      |> average()
      |> round()

  defp apply_strategy(orders, %Strategy{id: :top_three_average}),
    do:
      orders
      |> Enum.take(3)
      |> Enum.map(&platinum/1)
      |> average()
      |> round()

  defp apply_strategy(orders, %Strategy{id: :equal_to_lowest}),
    do:
      orders
      |> Enum.take(1)
      |> Enum.map(&platinum/1)
      |> List.first()

  defp apply_strategy(orders, %Strategy{id: :lowest_minus_one}),
    do:
      orders
      |> Enum.take(1)
      |> Enum.map(&platinum_minus_one/1)
      |> List.first()

  @spec platinum(OrderInfo.t()) :: non_neg_integer
  defp platinum(order), do: order.platinum

  @spec platinum_minus_one(OrderInfo.t()) :: integer
  defp platinum_minus_one(order), do: order.platinum - 1

  @spec average([number]) :: number
  defp average(prices), do: Enum.sum(prices) / length(prices)

  @spec apply_boundaries(integer, Product.t()) :: pos_integer
  defp apply_boundaries(price, %Product{default_price: default}) when price == 0, do: default
  defp apply_boundaries(price, %Product{min_price: min}) when price < min, do: min
  defp apply_boundaries(price, _product) when price > 0, do: price
end
