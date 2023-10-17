defmodule WebInterface.Persistence.StrategyTest do
  @moduledoc false

  use ExUnit.Case

  alias ETS
  alias Shared.Data.Strategy
  alias WebInterface.Persistence.Strategy, as: StrategyStore

  describe "get_strategies" do
    test "returns all the strategies" do
      expected_strategies =
        Enum.sort([
          Strategy.new(
            name: "Top 3 Average",
            id: :top_three_average,
            description: "Gets the 3 lowest prices for the given item and calculates the average."
          ),
          Strategy.new(
            name: "Top 5 Average",
            id: :top_five_average,
            description: "Gets the 5 lowest prices for the given item and calculates the average."
          ),
          Strategy.new(
            name: "Equal to lowest",
            id: :equal_to_lowest,
            description: "Gets the lowest price for the given item and uses it."
          ),
          Strategy.new(
            name: "Lowest minus one",
            id: :lowest_minus_one,
            description: "Gets the lowest price for the given item and beats it by 1."
          )
        ])

      {:ok, actual_strategies} = StrategyStore.get_strategies()

      assert Enum.sort(actual_strategies) == expected_strategies
    end
  end

  describe "get_strategy_by_id" do
    test "returns the strategy with the given id" do
      expected_strategy =
        Strategy.new(
          name: "Top 3 Average",
          id: :top_three_average,
          description: "Gets the 3 lowest prices for the given item and calculates the average."
        )

      {:ok, actual_strategy} = StrategyStore.get_strategy_by_id("top_three_average")

      assert actual_strategy == expected_strategy
    end

    test "returns error if no strategy is found" do
      assert {:error, :not_found} == StrategyStore.get_strategy_by_id("error")
    end
  end

  describe "get_selected_strategy && set_selected_strategy" do
    test "returns nil if no strategy is selected" do
      {:ok, actual_strategy} = StrategyStore.get_selected_strategy()
      assert is_nil(actual_strategy)
    end

    test "sets and returns strategy correctly" do
      expected_strategy =
        Strategy.new(
          name: "Top 3 Average",
          id: :top_three_average,
          description: "Gets the 3 lowest prices for the given item and calculates the average."
        )

      :ok = StrategyStore.set_selected_strategy(expected_strategy)

      {:ok, actual_strategy} = StrategyStore.get_selected_strategy()
      assert actual_strategy == expected_strategy
    end
  end
end
