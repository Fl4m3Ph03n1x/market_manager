defmodule MarketManagerTest do
  use ExUnit.Case, async: false

  alias MarketManager.CLI

  @orders_filename Application.compile_env!(:market_manager, :current_orders)

  defp create_empty_orders_file, do: File.touch!(@orders_filename)
  defp delete_orders_file, do: File.rm!(@orders_filename)

  defp create_orders_file(syndicate, uuids) do
    content =
      Jason.encode!(%{
        syndicate => uuids
      })

    File.write!(@orders_filename, content)
  end

  describe "activate syndicate" do
    setup do
      create_empty_orders_file()
      on_exit(&delete_orders_file/0)
    end

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

  describe "deactivate syndicate" do
    setup do
      on_exit(&delete_orders_file/0)
    end

    test "Deletes order from market " do
      # Arrange
      params = ["--action=deactivate", "--syndicates=red_veil"]
      syndicate = "red_veil"
      orders = ["5ee71a2604d55c0a5cbdc3c2", "5ee71a2604d55c0a5cbdc3c2"]
      create_orders_file(syndicate, orders)

      # Act
      actual_response = CLI.main(params)
      expected_response = [{:ok, :success}]

      actual_orders =
        @orders_filename
        |> File.read!()
        |> Jason.decode!()

      expected_orders = %{
        "red_veil" => []
      }

      # Assert
      assert actual_response == expected_response
      assert actual_orders == expected_orders
    end
  end
end
