defmodule WebInterface.Persistence.User do
  @moduledoc """
  Persistence module for user related data.
  """

  alias Shared.Data.User
  alias WebInterface.Persistence

  @spec set_user(User.t() | nil, Persistence.table()) :: :ok | {:error, any()}
  def set_user(user, table \\ Persistence.default_table()) do
    with {:ok, table_ref} <- table.recover.(table.name),
         {:ok, _updated_table_ref} <- table.put.(table_ref, :user, user) do
      :ok
    end
  end

  @spec get_user(Persistence.table()) :: {:ok, User.t() | nil} | {:error, any()}
  def get_user(table \\ Persistence.default_table()) do
    with {:ok, table_ref} <- table.recover.(table.name) do
      table.get.(table_ref, :user, nil)
    end
  end

  @spec has_user?(Persistence.table()) :: boolean()
  def has_user?(table \\ Persistence.default_table()) do
    case get_user(table) do
      {:ok, nil} -> false
      {:ok, _user} -> true
      _error -> false
    end
  end
end
