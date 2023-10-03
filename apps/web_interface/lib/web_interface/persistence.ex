defmodule WebInterface.Persistence do
  @moduledoc """
  Responsible for temporary persistence in WebInterface. Saves state that needs to be shared between LiveViews.
  Uses ETS beneath the scenes.
  """

  alias ETS
  alias Shared.Data.{Strategy, Syndicate, User}

  @table_name :data

  @spec init([Strategy.t()], [Syndicate.t()], User.t()) :: :ok | {:error, any}
  def init(strategies, syndicates, user) do
    with {:ok, table} <- ETS.KeyValueSet.new(name: @table_name, protection: :public),
         {:ok, table} <- ETS.KeyValueSet.put(table, :syndicates, syndicates),
         {:ok, table} <- ETS.KeyValueSet.put(table, :strategies, strategies),
         {:ok, _table} <- ETS.KeyValueSet.put(table, :user, user) do
      :ok
    end
  end

  @spec table :: atom
  def table, do: @table_name
end
