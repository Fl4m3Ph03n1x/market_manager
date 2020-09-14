defmodule Cli.ValidatorTest do
  use ExUnit.Case, async: false

  import Mock

  alias Cli.Validator

  describe "validate" do
    test "returns error if strategy is invalid" do
      with_mock Manager, [
        valid_strategy?: fn("invalid_strategy") -> false end,
        valid_action?: fn nil -> true end,
        valid_syndicate?: fn nil -> true end
      ] do
        # Arrange
        params = %{
          syndicates: [nil],
          action: nil,
          strategy: "invalid_strategy"
        }
        deps = %{manager: Manager}

        # Act
        actual_response = Validator.validate(params, deps)
        expected_response = {:error, [%{input: "invalid_strategy", type: :unknown_strategy}]}

        # Assert
        assert actual_response == expected_response
      end
    end

    test "returns error if a syndicate is invalid" do
      with_mock Manager, [
        valid_strategy?: fn nil -> true end,
        valid_action?: fn nil -> true end,
        valid_syndicate?: fn
          ("invalid_syndicate") -> false
          ("new_loka") -> true
        end
      ] do
        # Arrange
        params = %{
          syndicates: ["new_loka", "invalid_syndicate"],
          action: nil,
          strategy: nil
        }
        deps = %{manager: Manager}

        # Act
        actual_response = Validator.validate(params, deps)
        expected_response = {:error, [%{input: "invalid_syndicate", type: :unknown_syndicate}]}

        # Assert
        assert actual_response == expected_response
      end
    end

    test "returns error if multiple syndicates are invalid" do
      with_mock Manager, [
        valid_strategy?: fn nil -> true end,
        valid_action?: fn nil -> true end,
        valid_syndicate?: fn
          ("invalid_syndicate1") -> false
          ("invalid_syndicate2") -> false
        end
      ] do
        # Arrange
        params = %{
          syndicates: ["invalid_syndicate1", "invalid_syndicate2"],
          action: nil,
          strategy: nil
        }
        deps = %{manager: Manager}

        # Act
        actual_response = Validator.validate(params, deps)
        expected_response = {:error, [
          %{input: "invalid_syndicate1", type: :unknown_syndicate},
          %{input: "invalid_syndicate2", type: :unknown_syndicate},
        ]}

        # Assert
        assert actual_response == expected_response
      end
    end


    test "returns error if an action is invalid" do
      with_mock Manager, [
        valid_strategy?: fn nil -> true end,
        valid_action?: fn "invalid_action" -> false end,
        valid_syndicate?: fn nil -> true end
      ] do
        # Arrange
        params = %{
          syndicates: [nil],
          action: "invalid_action",
          strategy: nil
        }
        deps = %{manager: Manager}

        # Act
        actual_response = Validator.validate(params, deps)
        expected_response = {:error, [%{input: "invalid_action", type: :unknown_action}]}

        # Assert
        assert actual_response == expected_response
      end
    end

    test "returns multiple errors if multiple parameters are invalid" do
      with_mock Manager, [
        valid_strategy?: fn("invalid_strategy") -> false end,
        valid_action?: fn ("invalid_action") -> false end,
        valid_syndicate?: fn nil -> true end
      ] do
        # Arrange
        params = %{
          syndicates: [nil],
          action: "invalid_action",
          strategy: "invalid_strategy"
        }
        deps = %{manager: Manager}

        # Act
        actual_response = Validator.validate(params, deps)
        expected_response = {:error, [
          %{input: "invalid_action", type: :unknown_action},
          %{input: "invalid_strategy", type: :unknown_strategy}
        ]}

        # Assert
        assert actual_response == expected_response
      end
    end

    test "returns ok tupple with data if everything is valid" do
      with_mock Manager, [
        valid_strategy?: fn("equal_to_lowest") -> true end,
        valid_action?: fn ("activate") -> true end,
        valid_syndicate?: fn "red_veil" -> true end
      ] do
        # Arrange
        params = %{
          syndicates: ["red_veil"],
          action: "activate",
          strategy: "equal_to_lowest"
        }
        deps = %{manager: Manager}

        # Act
        actual_response = Validator.validate(params, deps)
        expected_response = {:ok, %{
          action: "activate",
          strategy: :equal_to_lowest,
          syndicates: ["red_veil"]
        }}

        # Assert
        assert actual_response == expected_response
      end
    end
  end
end
