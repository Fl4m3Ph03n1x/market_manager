defmodule Manager.PriceAnalyst do
  @moduledoc """
  Contains the formulas and calculations for all the strategies.
  Strategies calculate the optimum price for you to sell an item.
  There are several stretagies, some focus more on selling fast, while others
  on getting more profit.
  """

  alias Manager
  alias Manager.{AuctionHouse, Store}

  @strategies [
    "top_five_average",
    "top_three_average",
    "equal_to_lowest",
    "lowest_minus_one"
  ]

  ##########
  # Public #
  ##########

  @spec valid_strategy?(String.t) :: boolean
  def valid_strategy?(strategy), do: strategy in @strategies

  @spec calculate_price(Store.product, [AuctionHouse.order_info], Manager.strategy) :: non_neg_integer
  def calculate_price(product, all_orders, strategy), do:
    all_orders
    |> pre_process_orders()
    |> apply_strategy(strategy)
    |> apply_boundaries(product)
    |> round()

  ###########
  # Private #
  ###########

  defp pre_process_orders(all_orders), do:
    all_orders
    |> Enum.filter(&visible?/1)
    |> Enum.filter(&user_ingame?/1)
    |> Enum.filter(&platform_pc?/1)
    |> Enum.filter(&sell_order?/1)
    |> Enum.sort(&price_ascending/2)

  @spec visible?(AuctionHouse.order_info) :: boolean
  defp visible?(order), do: Map.get(order, "visible") == true

  @spec user_ingame?(AuctionHouse.order_info) :: boolean
  defp user_ingame?(order), do: get_in(order, ["user", "status"]) == "ingame"

  @spec platform_pc?(AuctionHouse.order_info) :: boolean
  defp platform_pc?(order), do: Map.get(order, "platform") == "pc"

  @spec sell_order?(AuctionHouse.order_info) :: boolean
  defp sell_order?(order), do: Map.get(order, "order_type") == "sell"

  @spec price_ascending(AuctionHouse.order_info, AuctionHouse.order_info) :: boolean
  defp price_ascending(order1, order2), do: Map.get(order1, "platinum") < Map.get(order2, "platinum")

  @spec apply_strategy([AuctionHouse.order_info], Manager.strategy) :: number
  defp apply_strategy([], _strategy), do: 0

  defp apply_strategy([%{"platinum" => price}], _strategy), do: price

  defp apply_strategy(orders, :top_five_average), do:
    orders
    |> Enum.take(5)
    |> Enum.map(&platinum/1)
    |> average()

  defp apply_strategy(orders, :top_three_average), do:
    orders
    |> Enum.take(3)
    |> Enum.map(&platinum/1)
    |> average()

  defp apply_strategy(orders, :equal_to_lowest), do:
    orders
    |> Enum.take(1)
    |> Enum.map(&platinum/1)
    |> List.first()

  defp apply_strategy(orders, :lowest_minus_one), do:
    orders
    |> Enum.take(1)
    |> Enum.map(&platinum_minus_one/1)
    |> List.first()

  @spec platinum(AuctionHouse.order_info) :: non_neg_integer
  defp platinum(order), do: Map.get(order, "platinum")

  @spec platinum_minus_one(AuctionHouse.order_info) :: integer
  defp platinum_minus_one(order), do: Map.get(order, "platinum") - 1

  @spec average([number]) :: number
  defp average(prices), do: Enum.sum(prices) / length(prices)

  @spec apply_boundaries(non_neg_integer, Store.product) :: non_neg_integer
  defp apply_boundaries(price, %{"default_price" => default}) when price == 0, do: default
  defp apply_boundaries(price, %{"min_price" => min}) when price < min, do: min
  defp apply_boundaries(price, _product), do: price
end
