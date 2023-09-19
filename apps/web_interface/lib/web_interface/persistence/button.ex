defmodule WebInterface.Persistence.Button do
  @moduledoc """
  Persistence module to know which buttons are selected.
  """

  alias ETS
  alias Shared.Data.User
  alias WebInterface.Persistence

  @spec set_button(atom) :: :ok | {:error, any}
  def set_button(button) when is_atom(button) do
    with {:ok, table} <- ETS.KeyValueSet.wrap_existing(Persistence.table()),
         {:ok, _updated_table} <- ETS.KeyValueSet.put(table, :button, button) do
      :ok
    end
  end

  @spec get_button :: {:ok, atom | nil} | {:error, any}
  def get_button do
    with {:ok, table} <- ETS.KeyValueSet.wrap_existing(Persistence.table()) do
      ETS.KeyValueSet.get(table, :button, nil)
    end
  end

  @spec button_selected?(atom) :: boolean
  def button_selected?(button) when is_atom(button) do
    case get_button() do
      {:ok, nil} -> false
      {:ok, active_button} -> button == active_button
      _error -> false
    end
  end
end
