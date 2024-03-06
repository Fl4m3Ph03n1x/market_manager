defmodule WebInterface.Persistence.StrategyTest do
  @moduledoc false

  use ExUnit.Case, async: true

  alias Shared.Data.Strategy
  alias WebInterface.Persistence.Strategy, as: StrategyStore

  setup do
    strategies =
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

    %{
      table: %{
        recover: fn :data -> {:ok, :table_ref} end,
        get: fn :table_ref, :strategies -> {:ok, strategies} end,
        name: :data
      },
      strategies: strategies
    }
  end

  describe "get_strategies" do
    test "returns all the strategies", setup do
      assert StrategyStore.get_strategies(setup.table) == {:ok, setup.strategies}
    end
  end

  describe "get_strategy_by_id" do
    test "returns the strategy with the given id", setup do
      expected_strategy =
        Strategy.new(
          name: "Top 3 Average",
          id: :top_three_average,
          description: "Gets the 3 lowest prices for the given item and calculates the average."
        )

      {:ok, actual_strategy} = StrategyStore.get_strategy_by_id("top_three_average", setup.table)

      assert actual_strategy == expected_strategy
    end

    test "returns error if no strategy is found", setup do
      assert {:error, :not_found} == StrategyStore.get_strategy_by_id("error", setup.table)
    end
  end

  describe "get_selected_strategy" do
    test "returns selected strategy", setup do
      table =
        Map.merge(setup.table, %{
          get: fn :table_ref, :selected_strategy, nil -> {:ok, nil} end
        })

      {:ok, actual_strategy} = StrategyStore.get_selected_strategy(table)
      assert is_nil(actual_strategy)
    end
  end

  describe "set_selected_strategy" do
    test "sets and returns strategy correctly", setup do
      table =
        Map.merge(setup.table, %{
          put: fn :table_ref, :selected_strategy, nil -> {:ok, :table_ref} end
        })

      assert StrategyStore.set_selected_strategy(nil, table) == :ok
    end
  end
end
