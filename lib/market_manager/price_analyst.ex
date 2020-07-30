defmodule MarketManager.PriceAnalyst do
  @moduledoc """
  Contains the formulas and calculations for all the strategies.
  Strategies calculate the optimum price for you to sell an item.
  There are several stretagies, some focus more on selling fast, while others
  on getting more profit.
  """

  ##########
  # Public #
  ##########

  def calculate_price(all_orders, strategy), do:
    all_orders
    |> pre_process_orders()
    |> apply_strategy(strategy)
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

  defp visible?(order), do: Map.get(order, "visible") == true

  defp user_ingame?(order), do: get_in(order, ["user", "status"]) == "ingame"

  defp platform_pc?(order), do: Map.get(order, "platform") == "pc"

  defp sell_order?(order), do: Map.get(order, "order_type") == "sell"

  defp price_ascending(order1, order2), do: Map.get(order1, "platinum") < Map.get(order2, "platinum")

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
    |> IO.inspect()
    |> Enum.take(1)
    |> Enum.map(&platinum/1)
    |> List.first()

  defp apply_strategy(orders, :lowest_minus_one), do:
    orders
    |> Enum.take(1)
    |> Enum.map(&platinum_minus_one/1)
    |> List.first()

  defp platinum(order), do: Map.get(order, "platinum")

  defp platinum_minus_one(order), do: Map.get(order, "platinum") - 1

  defp average(prices), do: Enum.sum(prices) / length(prices)
end
