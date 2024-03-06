defmodule WebInterface.Persistence.OperationProgress do
  @moduledoc """
  Persistence module used to track operation progress.
  """

  alias WebInterface.Persistence

  @spec in_progress?(Persistence.table()) :: {:ok, boolean()} | {:error, any()}
  def in_progress?(table \\ Persistence.default_table()) do
    with {:ok, table_ref} <- table.recover.(table.name),
         {:ok, result} <- table.get.(table_ref, :operation_in_progress, false) do
      result
    end
  end

  @spec set_progress(boolean(), Persistence.table()) :: :ok | {:error, any()}
  def set_progress(active?, table \\ Persistence.default_table()) do
    with {:ok, table_ref} <- table.recover.(table.name),
         {:ok, _new_table} <- table.put.(table_ref, :operation_in_progress, active?) do
      :ok
    end
  end
end
