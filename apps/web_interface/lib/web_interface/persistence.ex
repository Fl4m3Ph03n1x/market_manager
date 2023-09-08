defmodule WebInterface.Persistence do
  @moduledoc """
  Responsible for temporary persistence in WebInterface. Saves state that needs to be shared between LiveViews.
  Uses ETS beneath the scenes.
  """

  alias ETS
  @table_name :data

  @spec init([Strategy.t()], [Syndicate.t()]) :: :ok | {:error, any}
  def init(strategies, syndicates) do
    with {:ok, new_table} <- ETS.KeyValueSet.new(name: @table_name, protection: :public),
         {:ok, table_with_syndicates} <- ETS.KeyValueSet.put(new_table, :syndicates, syndicates),
         {:ok, _table} <- ETS.KeyValueSet.put(table_with_syndicates, :strategies, strategies) do
      :ok
    end
  end

  @spec table :: atom
  def table, do: @table_name
end
