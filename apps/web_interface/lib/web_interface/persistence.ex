defmodule WebInterface.Persistence do
  @moduledoc """
  Responsible for temporary persistence in WebInterface. Uses ETS beneath the scenes.
  """

  alias ETS
  alias Shared.Data.User

  @table_name :data

  @spec init :: :ok | {:error, any}
  def init do
    with {:ok, _table} <- ETS.KeyValueSet.new(name: @table_name, protection: :public) do
      :ok
    end
  end

  @spec set_user(User.t) :: :ok | {:error, any}
  def set_user(%User{} = user) do
    with {:ok, table} <- ETS.KeyValueSet.wrap_existing(@table_name),
      {:ok, _updated_table} <- ETS.KeyValueSet.put(table, :user, user) do
        :ok
      end
  end

  @spec get_user :: {:ok, User.t} | {:error, any}
  def get_user do
    with {:ok, table} <- ETS.KeyValueSet.wrap_existing(@table_name) do
      ETS.KeyValueSet.get(table, :user)
    end
  end

  @spec has_user? :: boolean
  def has_user? do
    case get_user() do
      {:ok, nil} -> false
      {:ok, _user} -> true
      _error -> false
    end
  end
end
