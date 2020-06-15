defmodule MarketManagerTest do
  use ExUnit.Case, async: false

  alias MarketManager.CLI

  @orders_filename Application.compile_env!(:market_manager, :current_orders)

  setup do
    File.touch!(@orders_filename)
    on_exit(&delete_orders_file/0)
  end

  defp delete_orders_file, do: File.rm!(@orders_filename)

  test "Places orders from a syndicate in the market" do
    # Arrange
    params = ["--action=activate", "--syndicates=red_veil"]

    # Act
    actual_response = CLI.main(params)
    expected_response = [{:ok, :success}]

    actual_orders =
      @orders_filename
      |> File.read!()
      |> Jason.decode!()
    expected_orders = %{
      "red_veil" => ["5ee71a2604d55c0a5cbdc3c2", "5ee71a2604d55c0a5cbdc3c2"]
    }

    # Assert
    assert actual_response == expected_response
    assert actual_orders == expected_orders
  end

  test "Places orders from multiple syndicates in the market" do
    # Arrange
    params = ["--action=activate", "--syndicates=red_veil,new_loka"]

    # Act
    actual_response = CLI.main(params)
    expected_response = [{:ok, :success}, {:ok, :success}]

    actual_orders =
      @orders_filename
      |> File.read!()
      |> Jason.decode!()
    expected_orders = %{
      "red_veil" => ["5ee71a2604d55c0a5cbdc3c2", "5ee71a2604d55c0a5cbdc3c2"],
      "new_loka" => ["5ee71a2604d55c0a5cbdc3c2", "5ee71a2604d55c0a5cbdc3c2"]
    }

    # Assert
    assert actual_response == expected_response
    assert actual_orders == expected_orders
  end
end
