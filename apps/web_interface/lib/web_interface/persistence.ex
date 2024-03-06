defmodule WebInterface.Persistence do
  @moduledoc """
  Responsible for temporary persistence in WebInterface. Saves state that needs to be shared between LiveViews.
  Uses ETS beneath the scenes.
  """

  alias ETS
  alias Shared.Data.{Strategy, Syndicate, User}

  @type table :: %{
          new: (ETS.KeyValueSet.set_options() -> {:error, any()} | {:ok, ETS.KeyValueSet.t()}),
          put: (ETS.KeyValueSet.t(), any(), any() -> {:error, any()} | {:ok, ETS.KeyValueSet.t()}),
          get: (ETS.KeyValueSet.t(), any(), any() -> {:error, any()} | {:ok, any()}),
          recover: (ETS.table_identifier() -> {:error, any()} | {:ok, ETS.KeyValueSet.t()}),
          name: atom()
        }

  @default_table %{
    new: &ETS.KeyValueSet.new/1,
    put: &ETS.KeyValueSet.put/3,
    get: &ETS.KeyValueSet.get/3,
    recover: &ETS.KeyValueSet.wrap_existing/1,
    name: :data
  }

  @spec init([Strategy.t()], [Syndicate.t()], User.t(), table()) :: :ok | {:error, any}
  def init(
        strategies,
        syndicates,
        user,
        %{name: name, new: new, put: put} = _table_data \\ @default_table
      ) do
    with {:ok, table} <- new.(name: name, protection: :public),
         {:ok, table} <- put.(table, :syndicates, syndicates),
         {:ok, table} <- put.(table, :strategies, strategies),
         {:ok, _table} <- put.(table, :user, user) do
      :ok
    end
  end

  @spec default_table :: table()
  def default_table, do: @default_table
end
