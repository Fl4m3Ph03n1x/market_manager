defmodule WebInterface.Persistence.User do
  @moduledoc """
  Persistence module for user related data.
  """

  alias ETS
  alias Shared.Data.User
  alias WebInterface.Persistence

  @spec set_user(User.t() | nil) :: :ok | {:error, any}
  def set_user(user) do
    with {:ok, table} <- ETS.KeyValueSet.wrap_existing(Persistence.table()),
         {:ok, _updated_table} <- ETS.KeyValueSet.put(table, :user, user) do
      :ok
    end
  end

  @spec get_user :: {:ok, User.t() | nil} | {:error, any}
  def get_user do
    with {:ok, table} <- ETS.KeyValueSet.wrap_existing(Persistence.table()) do
      ETS.KeyValueSet.get(table, :user, nil)
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
