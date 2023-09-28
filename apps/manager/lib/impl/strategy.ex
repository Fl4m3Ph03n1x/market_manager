defmodule Manager.Impl.Strategy do
  @moduledoc """
  Behaviour that specifies the functions any strategy must implement. It is mostly used to provide an implementation of
  the Strategy pattern from OO languages, but adapted to Elixir.

  The pricing strategy will be selected and executed dynamically at runtime, as long as it implements this behaviour.
  """

  alias Shared.Data.{OrderInfo, Strategy}

  ##########
  # Public #
  ##########

  @spec module_to_id(module) :: atom
  def module_to_id(module_name), do:
    module_name
    |> Module.split()
    |> List.last()
    |> Macro.underscore()
    |> String.to_atom()

  @spec id_to_module(atom) :: module
  def id_to_module(id) do
    strategy_module_name =
      id
      |> Atom.to_string()
      |> Macro.camelize()

    Module.safe_concat([__MODULE__, strategy_module_name])
  end

  #############
  # Callbacks #
  #############

  @callback calculate_price([OrderInfo.t()]) :: pos_integer()

  @callback info :: Strategy.t()
end
