defmodule Manager.Impl.Strategy.LowestMinusOne do
  @moduledoc """
  Gets the lowest price for the given item and beats it by 1.
  """

  alias Manager.Impl.Strategy, as: StrategyInterface
  alias Shared.Data.{OrderInfo, Strategy}

  @behaviour StrategyInterface

  @impl StrategyInterface
  def calculate_price(orders) do
    orders
    |> Enum.take(1)
    |> Enum.map(&platinum_minus_one/1)
    |> List.first()
  end

  @impl StrategyInterface
  def info,
    do:
      Strategy.new(
        name: "Lowest minus one",
        id: StrategyInterface.module_to_id(__MODULE__),
        description: "Gets the lowest price for the given item and beats it by 1."
      )

  @spec platinum_minus_one(OrderInfo.t()) :: pos_integer
  defp platinum_minus_one(%OrderInfo{platinum: platinum}) when platinum <= 1, do: 1
  defp platinum_minus_one(%OrderInfo{platinum: platinum}), do: platinum - 1
end
