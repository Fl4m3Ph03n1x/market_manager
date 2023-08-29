defmodule WebInterface.Persistence do
  @moduledoc """
  Responsible for temporary persistence in WebInterface. Saves state that needs to be shared between LiveViews.
  Uses ETS beneath the scenes.
  """

  alias ETS
  alias Shared.Data.{Strategy, Syndicate, User}

  @table_name :data

  @spec init([Strategy.t()], [Syndicate.t()]) :: :ok | {:error, any}
  def init(strategies, syndicates) do
    with {:ok, new_table} <- ETS.KeyValueSet.new(name: @table_name, protection: :public),
      {:ok, table_with_syndicates} <- ETS.KeyValueSet.put(new_table, :syndicates, syndicates),
      {:ok, _table} <- ETS.KeyValueSet.put(table_with_syndicates, :strategies, strategies)  do
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

  @spec get_syndicates :: {:ok, [Syndicate.t()]} | {:error, any}
  def get_syndicates do
    with {:ok, table} <- ETS.KeyValueSet.wrap_existing(@table_name) do
      ETS.KeyValueSet.get(table, :syndicates)
    end
  end

  @spec get_strategies :: {:ok, [Strategy.t()]} | {:error, any}
  def get_strategies do
    with {:ok, table} <- ETS.KeyValueSet.wrap_existing(@table_name) do
      ETS.KeyValueSet.get(table, :strategies)
    end
  end

  @spec get_strategy_by_id(String.t()) :: {:ok, Strategy.t()} | {:error, any}
  def get_strategy_by_id(id) do
    with {:ok, table} <- ETS.KeyValueSet.wrap_existing(@table_name),
     {:ok, strategies} <- ETS.KeyValueSet.get(table, :strategies) do
      {:ok, Enum.find(strategies, fn strategy -> strategy.id == String.to_existing_atom(id) end)}
    end
  end

  @spec get_all_syndicates_by_id([String.t()]) :: {:ok, [Syndicate.t()]} | {:error, any}
  def get_all_syndicates_by_id(ids) do
    valid_ids = Enum.filter(ids, fn id -> id != "" end)

    with {:ok, table} <- ETS.KeyValueSet.wrap_existing(@table_name),
     {:ok, syndicates} <- ETS.KeyValueSet.get(table, :syndicates) do

      all_syndicates =
        for syndicate <- syndicates, id <- valid_ids, syndicate.id == String.to_existing_atom(id), do: syndicate

      {:ok, all_syndicates}
    end
  end

  @spec get_syndicate_by_id(String.t()) :: {:ok, Syndicate.t()} | {:error, any}
  def get_syndicate_by_id(id) do
    with {:ok, table} <- ETS.KeyValueSet.wrap_existing(@table_name),
     {:ok, syndicates} <- ETS.KeyValueSet.get(table, :syndicates) do
      {:ok, Enum.find(syndicates, fn syndicate -> syndicate.id == String.to_existing_atom(id) end)}
    end
  end

  @spec activate_syndicate(Syndicate.t) :: :ok | {:error, any}
  def activate_syndicate(syndicate), do: set_syndicate(syndicate, true)

  @spec deactivate_syndicate(Syndicate.t) :: :ok | {:error, any}
  def deactivate_syndicate(syndicate), do: set_syndicate(syndicate, false)

  @spec set_syndicate(Syndicate.t, boolean) :: :ok | {:error, any}
  defp set_syndicate(syndicate, value) do
    with {:ok, table} <- ETS.KeyValueSet.wrap_existing(@table_name),
      {:ok, active_syndicates} <- ETS.KeyValueSet.get(table, :active_syndicates, nil) do

        updated_active_syndicates =
          cond do
            is_nil(active_syndicates) and not value -> MapSet.new()
            is_nil(active_syndicates) -> MapSet.new() |> MapSet.put(syndicate)
            not value -> MapSet.delete(active_syndicates, syndicate)
            true -> MapSet.put(active_syndicates, syndicate)
          end

        ETS.KeyValueSet.put(table, :active_syndicates, updated_active_syndicates)
      end
  end

  @spec syndicate_active?(atom) :: boolean()
  def syndicate_active?(syndicate_id) do
    with {:ok, table} <- ETS.KeyValueSet.wrap_existing(@table_name),
    {:ok, true} <- ETS.KeyValueSet.get(table, syndicate_id) do
      true
    else
      _error -> false
    end
  end

  @spec all_syndicates_active? :: {:ok, boolean()} | {:error, any()}
  def all_syndicates_active? do
    with {:ok, table} <- ETS.KeyValueSet.wrap_existing(@table_name),
    {:ok, syndicates} <- ETS.KeyValueSet.get(table, :syndicates) do
      {:ok,
        syndicates
          |> Enum.map(fn synd -> synd.id end)
          |> Enum.all?(&syndicate_active?/1)
      }
    end
  end

  @spec get_active_syndicates :: {:ok, [Syndicate.t()]} | {:error, any()}
  def get_active_syndicates do
    with {:ok, table} <- ETS.KeyValueSet.wrap_existing(@table_name),
      {:ok, syndicates} <- ETS.KeyValueSet.get(table, :active_syndicates, []) do
        {:ok, Enum.to_list(syndicates)}
    end
  end

end
