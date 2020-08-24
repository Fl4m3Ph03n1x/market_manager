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

      deps = %{manager: ManagerMock}

      ManagerMock
      |> expect(:activate, fn ("red_veil", :equal_to_lowest) -> {:ok, :success} end)

      # Act
      actual_response = Cli.main(params, deps)
      expected_response = [{:ok, :success}]

      # Assert
      assert actual_response == expected_response
    end

    test "Places orders from multiple syndicates in the market" do
      # Arrange
      params = [
        "--action=activate",
        "--syndicates=red_veil,new_loka",
        "--strategy=equal_to_lowest"
      ]

      deps = %{manager: ManagerMock}

      ManagerMock
      |> expect(:activate, fn ("red_veil", :equal_to_lowest) -> {:ok, :success} end)
      |> expect(:activate, fn ("new_loka", :equal_to_lowest) -> {:ok, :success} end)

      # Act
      actual_response = Cli.main(params, deps)
      expected_response = [{:ok, :success}, {:ok, :success}]

      # Assert
      assert actual_response == expected_response
    end
  end

  describe "deactivate syndicate" do
    test "Deletes order from market " do
      # Arrange
      params = ["--action=deactivate", "--syndicates=red_veil"]
      syndicate = "red_veil"

      deps = %{manager: ManagerMock}

      ManagerMock
      |> expect(:deactivate, fn ^syndicate -> {:ok, :success} end)

      # Act
      actual_response = Cli.main(params, deps)
      expected_response = [{:ok, :success}]

      # Assert
      assert actual_response == expected_response
    end
  end

  describe "help instructions" do
    test "Prints instructions if invoked with no parameters" do
      # Arrange
      params = []

      # Act & Assert
      {_, _, _, _, %{"en" => docs}, _, _} = Code.fetch_docs(Cli)

      assert capture_log(fn ->
               assert Cli.main(params) == :ok
             end) =~ docs
    end

    test "Prints instructions if invoked with -h" do
      # Arrange
      params = ["-h"]

      # Act & Assert
      {_, _, _, _, %{"en" => docs}, _, _} = Code.fetch_docs(Cli)

      assert capture_log(fn ->
               assert Cli.main(params) == :ok
             end) =~ docs
    end

    test "Prints instructions if invoked with invalid parameters" do
      # Arrange
      params = ["--Bananas=yummi"]

      # Act & Assert
      {_, _, _, _, %{"en" => docs}, _, _} = Code.fetch_docs(Cli)

      assert capture_log(fn ->
               assert Cli.main(params) == :ok
             end) =~ docs
    end

    test "Prints instructions if invoked with unknown action" do
      # Arrange
      params = [
        "--action==yummi",
        "--syndicates=new_loka",
        "--strategy=equal_to_lowest"
      ]

      # Act & Assert
      {_, _, _, _, %{"en" => docs}, _, _} = Code.fetch_docs(Cli)

      assert capture_log(fn ->
               assert Cli.main(params) == {:error, :unknown_action, "=yummi"}
             end) =~ docs
    end

    test "Prints instructions if invoked with unknown strategy" do
      # Arrange
      params = [
        "--action=activate",
        "--syndicates=new_loka",
        "--strategy=banana"
      ]

      # Act & Assert
      {_, _, _, _, %{"en" => docs}, _, _} = Code.fetch_docs(Cli)

      assert capture_log(fn ->
               assert Cli.main(params) == {:error, :unknown_strategy, "banana"}
             end) =~ docs
    end
  end
end
