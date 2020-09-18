defmodule Cli.Validator do
  @moduledoc """
  Contains all the validation logic for CLI. Validates every input from the
  user to make sure the next stage only has to work with valid input.
  """

  alias Cli.{Error, Request}

  ##########
  # Public #
  ##########

  @spec validate(Request.t, %{manager: atom}) :: {:error, [Error.t]} | {:ok, Request.t}
  def validate(%Request{syndicates: syndicates, action: action, strategy: strategy}, %{manager: manager}) do
    errors =
      []
      |> validate_strategy(strategy, manager)
      |> validate_action(action, manager)
      |> validate_syndicates(syndicates, manager)

    if Enum.empty?(errors) do
      {:ok, Request.new(%{
        action: action,
        strategy: to_strategy(strategy),
        syndicates: syndicates
      })}
    else
      {:error, errors}
    end
  end

  ###########
  # Private #
  ###########

  @spec validate_strategy([Error.t], String.t | nil, module) :: [Error.t]
  defp validate_strategy(errors, strategy, manager) do
    if strategy == nil or manager.valid_strategy?(strategy) do
      errors
    else
      [Error.new(%{type: :unknown_strategy, input: strategy}) | errors]
    end
  end

  @spec validate_action([Error.t], String.t, module) :: [Error.t]
  defp validate_action(errors, action, manager) do
    if manager.valid_action?(action) do
      errors
    else
      [Error.new(%{type: :unknown_action, input: action}) | errors]
    end
  end

  @spec validate_syndicates([Error.t], [String.t], module) :: [Error.t]
  defp validate_syndicates(errors, syndicates, manager) do
    syndicate_errors =
      syndicates
      |> Enum.filter(&invalid_syndicate?(&1, manager))
      |> Enum.map(&to_syndicate_error/1)

    syndicate_errors ++ errors
  end

  @spec invalid_syndicate?(String.t, module) :: boolean
  defp invalid_syndicate?(syndicate, manager), do:
    not manager.valid_syndicate?(syndicate)

  @spec to_syndicate_error(String.t) :: Error.t
  defp to_syndicate_error(bad_syndicate), do:
    Error.new(%{type: :unknown_syndicate, input: bad_syndicate})

  @spec to_strategy(nil | String.t) :: nil | atom
  defp to_strategy(nil), do: nil
  defp to_strategy(strategy), do: String.to_atom(strategy)
end
