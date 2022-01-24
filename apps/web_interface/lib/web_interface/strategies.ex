defmodule WebInterface.Strategies do
  @moduledoc """
  Contains information about the strategies for price setting available to the user.
  """

  @spec list_strategies :: [
          %{
            description: String.t,
            id: :equal_to_lowest | :lowest_minus_one | :top_five_average | :top_three_average,
            name: String.t
          }
        ]
  def list_strategies,
    do: [
      %{
        name: "Top 3 Average",
        description: "
          Gets the 3 lowest prices for the given item and calculates the average.
        ",
        id: :top_three_average
      },
      %{
        name: "Top 5 Average",
        description: "
          Gets the 5 lowest prices for the given item and calculates the average.
        ",
        id: :top_five_average
      },
      %{
        name: "Equal to lowest",
        description: "
          Gets the lowest price for the given item and uses it.
        ",
        id: :equal_to_lowest
      },
      %{
        name: "Lowest minus one",
        description: "
          Gets the lowest price for the given item and beats it by 1.
        ",
        id: :lowest_minus_one
      }
    ]

  def get_strategy(id),
    do:
      list_strategies()
      |> Enum.filter(&by_id(&1, id))
      |> hd()

  defp by_id(%{id: strat_id}, id), do: strat_id == id
end
