defmodule CliTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureLog
  import Mock

  require Logger

  alias Cli
  alias Cli.Error

  describe "activate syndicate" do
    test "Places orders from a syndicate in the market" do
      with_mock Manager, [
        activate: fn("red_veil", :equal_to_lowest) -> {:ok, :success} end,
        valid_strategy?: fn("equal_to_lowest") -> true end,
        valid_action?: fn("activate") -> true end,
        valid_syndicate?: fn("red_veil") -> {:ok, true} end
      ] do
        # Arrange
        params = [
          "--action=activate",
          "--syndicates=red_veil",
          "--strategy=equal_to_lowest"
        ]

        deps = %{manager: Manager}

        # Act
        actual_response = Cli.main(params, deps)
        expected_response = [{:ok, :success}]

        # Assert
        assert actual_response == expected_response
      end
    end

    test "Places orders from multiple syndicates in the market" do
      with_mock(Manager, [
        activate: fn
          ("red_veil", :equal_to_lowest) -> {:ok, :success}
          ("new_loka", :equal_to_lowest) -> {:ok, :success}
        end,
        valid_strategy?: fn("equal_to_lowest") -> true end,
        valid_action?: fn("activate") -> true end,
        valid_syndicate?: fn
          "red_veil" -> {:ok, true}
          "new_loka" -> {:ok, true}
        end,
      ]) do
        # Arrange
        params = [
          "--action=activate",
          "--syndicates=red_veil,new_loka",
          "--strategy=equal_to_lowest"
        ]

        deps = %{manager: Manager}

        # Act
        actual_response = Cli.main(params, deps)
        expected_response = [{:ok, :success}, {:ok, :success}]

        # Assert
        assert actual_response == expected_response
      end
    end
  end

  describe "deactivate syndicate" do
    test "Deletes order from market " do
      with_mock Manager, [
        deactivate: fn("red_veil") -> {:ok, :success} end,
        valid_action?: fn("deactivate") -> true end,
        valid_syndicate?: fn("red_veil") -> {:ok, true} end
      ] do
        # Arrange
        params = ["--action=deactivate", "--syndicates=red_veil"]

        deps = %{manager: Manager}

        # Act
        actual_response = Cli.main(params, deps)
        expected_response = [{:ok, :success}]

        # Assert
        assert actual_response == expected_response
      end
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

    test "Prints instructions if an error occurs" do
      # Arrange
      params = ["--Bananas=yummi"]

      # Act & Assert
      {_, _, _, _, %{"en" => docs}, _, _} = Code.fetch_docs(Cli)

      assert capture_log(fn ->
               assert Cli.main(params) == {:error, [%Error{input: "--Bananas", type: :bad_option}]}
             end) =~ docs
    end
  end
end
