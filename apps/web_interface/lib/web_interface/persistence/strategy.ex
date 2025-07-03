defmodule WebInterface.Persistence.Strategy do
  @moduledoc """
  Persistence module for strategy data. Mostly to track which strategy is selected in the menu and access the list of
  strategies.
  """

  alias Shared.Data.Strategy
  alias WebInterface.Persistence

  @typep strategy_id :: String.t()

  @doc """
  Returns all the strategies known to the Manager.
  """
  @spec get_strategies(Persistence.table()) :: {:ok, [Strategy.t()]} | {:error, any()}
  def get_strategies(table \\ Persistence.default_table()) do
    with {:ok, table_ref} <- table.recover.(table.name) do
      table.get.(table_ref, :strategies, [])
    end
  end

  @doc """
  Returns a strategy entity, given its id.
  """
  @spec get_strategy_by_id(strategy_id(), Persistence.table()) :: {:ok, Strategy.t()} | {:error, any()}
  def get_strategy_by_id(id, table \\ Persistence.default_table()) do
    with {:ok, table_ref} <- table.recover.(table.name),
         {:ok, strategies} <- table.get.(table_ref, :strategies, []) do
      strategies
      |> Enum.find(fn strategy -> strategy.id == String.to_existing_atom(id) end)
      |> case do
        nil -> {:error, :not_found}
        strategy -> {:ok, strategy}
      end
    end
  end

  @doc """
  Marks a strategy as selected, for the web_interface only. Does not talk to the Manager.
  Unlike Syndicates, strategies cannot be disabled, as only a single strategy can be selected at any given time.
  """
  @spec set_selected_strategy(Strategy.t(), Persistence.table()) :: :ok | {:error, any()}
  def set_selected_strategy(strategy, table \\ Persistence.default_table()) do
    with {:ok, table_ref} <- table.recover.(table.name),
         {:ok, _updated_table} <- table.put.(table_ref, :selected_strategy, strategy) do
      :ok
    end
  end

  @doc """
  Returns the currently selected strategy in the Activate tab in the web_interface. Only one strategy may be selected at
  any given time, even though other strategies may be activate for other syndicates.
  """
  @spec get_selected_strategy(Persistence.table()) :: {:ok, Strategy.t() | nil} | {:error, any()}
  def get_selected_strategy(table \\ Persistence.default_table()) do
    case table.recover.(table.name) do
      {:ok, table_ref} -> table.get.(table_ref, :selected_strategy, nil)
      err -> err
    end
  end
end
