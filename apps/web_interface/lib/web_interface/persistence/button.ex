defmodule WebInterface.Persistence.Button do
  @moduledoc """
  Persistence module to know which buttons are selected.
  """

  alias WebInterface.Persistence

  @spec set_button(atom(), Persistence.table()) :: :ok | {:error, any()}
  def set_button(button, table \\ Persistence.default_table()) when is_atom(button) do
    with {:ok, table_ref} <- table.recover.(table.name),
         {:ok, _updated_table_ref} <- table.put.(table_ref, :button, button) do
      :ok
    end
  end

  @spec get_button(Persistence.table()) :: {:ok, atom()} | {:error, any()}
  def get_button(table \\ Persistence.default_table()) do
    with {:ok, table_ref} <- table.recover.(table.name) do
      table.get.(table_ref, :button, nil)
    end
  end

  @spec button_selected?(atom(), Persistence.table()) :: boolean()
  def button_selected?(button, table \\ Persistence.default_table()) when is_atom(button) do
    case get_button(table) do
      {:ok, nil} -> false
      {:ok, active_button} -> button == active_button
      _error -> false
    end
  end
end
