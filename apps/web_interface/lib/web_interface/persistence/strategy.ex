defmodule WebInterface.Persistence.Strategy do
  @moduledoc """
  Persistence module for strategy data. Mostly to track which strategy is selected in the menu and access the list of strategies.
  """

  alias ETS
  alias Shared.Data.Strategy
  alias WebInterface.Persistence

  @spec get_strategies :: {:ok, [Strategy.t()]} | {:error, any}
  def get_strategies do
    with {:ok, table} <- ETS.KeyValueSet.wrap_existing(Persistence.table()) do
      ETS.KeyValueSet.get(table, :strategies)
    end
  end

  @spec get_strategy_by_id(String.t()) :: {:ok, Strategy.t()} | {:error, any}
  def get_strategy_by_id(id) do
    with {:ok, table} <- ETS.KeyValueSet.wrap_existing(Persistence.table()),
         {:ok, strategies} <- ETS.KeyValueSet.get(table, :strategies) do
      strategies
      |> Enum.find(fn strategy -> strategy.id == String.to_existing_atom(id) end)
      |> case do
        nil -> {:error, :not_found}
        strategy -> {:ok, strategy}
      end
    end
  end

  @spec set_selected_strategy(Strategy.t()) :: :ok | {:error, any()}
  def set_selected_strategy(strategy) do
    with {:ok, table} <- ETS.KeyValueSet.wrap_existing(Persistence.table()),
         {:ok, _updated_table} <- ETS.KeyValueSet.put(table, :selected_strategy, strategy) do
      :ok
    end
  end

  @spec get_selected_strategy :: {:ok, Strategy.t()} | {:error, any()}
  def get_selected_strategy do
    case ETS.KeyValueSet.wrap_existing(Persistence.table()) do
      {:ok, table} -> ETS.KeyValueSet.get(table, :selected_strategy, nil)
      err -> err
    end
  end
end
