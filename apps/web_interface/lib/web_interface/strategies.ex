defmodule WebInterface.Strategies do
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
      }
    ]

  def get_strategy(id),
    do:
      list_strategies()
      |> Enum.filter(&by_id(&1, id))
      |> hd()

  defp by_id(%{id: strat_id}, id), do: strat_id == id
end
