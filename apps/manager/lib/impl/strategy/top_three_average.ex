defmodule Manager.Impl.Strategy.TopThreeAverage do
  @moduledoc """
  Gets the 3 lowest prices for the given item and calculates the average.
  """

  alias Manager.Impl.Strategy, as: StrategyInterface
  alias Shared.Data.{OrderInfo, Strategy}

  @behaviour StrategyInterface

  @impl StrategyInterface
  def calculate_price(orders) do
    orders
    |> Enum.take(3)
    |> Enum.map(&platinum/1)
    |> average()
    |> round()
  end

  @impl StrategyInterface
  def info, do:
    Strategy.new(
      name: "Top 3 Average",
      id: StrategyInterface.module_to_id(__MODULE__),
      description: "Gets the 3 lowest prices for the given item and calculates the average."
    )

  @spec platinum(OrderInfo.t()) :: pos_integer
  defp platinum(order), do: order.platinum

  @spec average([pos_integer]) :: number
  defp average(prices), do: Enum.sum(prices) / length(prices)
end
