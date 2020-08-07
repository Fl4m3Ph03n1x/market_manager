defmodule CliTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureLog
  import Hammox
  require Logger

  alias Cli
  alias Cli.ManagerMock

  describe "activate syndicate" do
    test "Places orders from a syndicate in the market" do
      # Arrange
      params = [
        "--action=activate",
        "--syndicates=red_veil",
        "--strategy=equal_to_lowest"
      ]

      ManagerMock
      |> expect(:activate, fn ("red_veil", :equal_to_lowest) -> {:ok, :success} end)

      # Act
      actual_response = Cli.main(params, [manager: ManagerMock])
      expected_response = [{:ok, :success}]

      # Assert
      assert actual_response == expected_response
    end

    # test "Places orders from multiple syndicates in the market" do
    #   # Arrange
    #   params = [
    #     "--action=activate",
    #     "--syndicates=red_veil,new_loka",
    #     "--strategy=equal_to_lowest"
    #   ]

    #   # Act
    #   actual_response = Cli.main(params)
    #   expected_response = [{:ok, :success}, {:ok, :success}]

    #   actual_orders =
    #     @orders_filename
    #     |> File.read!()
    #     |> Jason.decode!()

    #   expected_orders = %{
    #     "red_veil" => ["5ee71a2604d55c0a5cbdc3c2", "5ee71a2604d55c0a5cbdc3c2"],
    #     "new_loka" => ["5ee71a2604d55c0a5cbdc3c2", "5ee71a2604d55c0a5cbdc3c2"]
    #   }

    #   # Assert
    #   assert actual_response == expected_response
    #   assert actual_orders == expected_orders
    # end
  end

  # describe "deactivate syndicate" do

  #   test "Deletes order from market " do
  #     # Arrange
  #     params = ["--action=deactivate", "--syndicates=red_veil"]
  #     syndicate = "red_veil"
  #     orders = ["5ee71a2604d55c0a5cbdc3c2", "5ee71a2604d55c0a5cbdc3c2"]
  #     create_orders_file(syndicate, orders)

  #     # Act
  #     actual_response = Cli.main(params)
  #     expected_response = [{:ok, :success}]

  #     actual_orders =
  #       @orders_filename
  #       |> File.read!()
  #       |> Jason.decode!()

  #     expected_orders = %{
  #       "red_veil" => []
  #     }

  #     # Assert
  #     assert actual_response == expected_response
  #     assert actual_orders == expected_orders
  #   end
  # end

  # describe "help instructions" do
  #   test "Prints instructions if invoked with no parameters" do
  #     # Arrange
  #     params = []

  #     # Act & Assert
  #     {_, _, _, _, %{"en" => docs}, _, _} = Code.fetch_docs(Cli)

  #     assert capture_log(fn ->
  #              assert Cli.main(params) == :ok
  #            end) =~ docs
  #   end

  #   test "Prints instructions if invoked with -h" do
  #     # Arrange
  #     params = ["-h"]

  #     # Act & Assert
  #     {_, _, _, _, %{"en" => docs}, _, _} = Code.fetch_docs(Cli)

  #     assert capture_log(fn ->
  #              assert Cli.main(params) == :ok
  #            end) =~ docs
  #   end

  #   test "Prints instructions if invoked with invalid parameters" do
  #     # Arrange
  #     params = ["--Bananas=yummi"]

  #     # Act & Assert
  #     {_, _, _, _, %{"en" => docs}, _, _} = Code.fetch_docs(Cli)

  #     assert capture_log(fn ->
  #              assert Cli.main(params) == :ok
  #            end) =~ docs
  #   end

  #   test "Prints instructions if invoked with unknown action" do
  #     # Arrange
  #     params = [
  #       "--action==yummi",
  #       "--syndicates=new_loka",
  #       "--strategy=equal_to_lowest"
  #     ]

  #     # Act & Assert
  #     {_, _, _, _, %{"en" => docs}, _, _} = Code.fetch_docs(Cli)

  #     assert capture_log(fn ->
  #              assert Cli.main(params) == {:error, :unknown_action, "=yummi"}
  #            end) =~ docs
  #   end
  # end
end
