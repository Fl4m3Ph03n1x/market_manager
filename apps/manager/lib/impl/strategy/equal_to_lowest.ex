defmodule Manager.Impl.Strategy.EqualToLowest do
  @moduledoc """
  Gets the lowest price for the given item and uses it.
  """

  alias Manager.Impl.Strategy, as: StrategyInterface
  alias Shared.Data.{OrderInfo, Strategy}

  @behaviour StrategyInterface

  @impl StrategyInterface
  def calculate_price(orders) do
    orders
    |> Enum.take(1)
    |> Enum.map(&platinum/1)
    |> List.first()
  end

  @impl StrategyInterface
  def info,
    do:
      Strategy.new(
        name: "Equal to lowest",
        id: StrategyInterface.module_to_id(__MODULE__),
        description: "Gets the lowest price for the given item and uses it."
      )

  @spec platinum(OrderInfo.t()) :: pos_integer
  defp platinum(order), do: order.platinum
end
