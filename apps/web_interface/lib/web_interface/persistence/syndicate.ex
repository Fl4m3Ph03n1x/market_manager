defmodule WebInterface.Persistence.Syndicate do
  @moduledoc """
  Persistence module for syndicate data. Mostly to track selected options in the menu and access the list of
  syndicates.
  """

  require Logger

  alias Shared.Data.Syndicate
  alias WebInterface.Persistence

  @typep syndicate_id :: String.t()
  @typep key :: atom()

  @spec get_syndicates(Persistence.table()) :: {:ok, [Syndicate.t()]} | {:error, any}
  def get_syndicates(table \\ Persistence.default_table()) do
    with {:ok, table_ref} <- table.recover.(table.name) do
      table.get.(table_ref, :syndicates, [])
    end
  end

  @spec get_all_syndicates_by_id([syndicate_id()], Persistence.table()) :: {:ok, [Syndicate.t()]} | {:error, any}
  def get_all_syndicates_by_id(ids, table \\ Persistence.default_table()) do
    valid_ids = Enum.filter(ids, fn id -> id != "" end)

    with {:ok, table_ref} <- table.recover.(table.name),
         {:ok, syndicates} <- table.get.(table_ref, :syndicates, []) do
      all_syndicates =
        for syndicate <- syndicates,
            id <- valid_ids,
            syndicate.id == String.to_existing_atom(id),
            do: syndicate

      {:ok, all_syndicates}
    end
  end

  @spec get_syndicate_by_id(String.t(), Persistence.table()) :: {:ok, Syndicate.t()} | {:error, any}
  def get_syndicate_by_id(id, table \\ Persistence.default_table()) do
    with {:ok, table_ref} <- table.recover.(table.name),
         {:ok, syndicates} <- table.get.(table_ref, :syndicates, []) do
      syndicates
      |> Enum.find(fn syndicate -> syndicate.id == String.to_existing_atom(id) end)
      |> case do
        nil -> {:error, :not_found}
        syndicate -> {:ok, syndicate}
      end
    end
  end

  @spec deactivate_syndicates([Syndicate.t()], Persistence.table()) :: :ok | [{:error, any}]
  def deactivate_syndicates(syndicates, table \\ Persistence.default_table()) do
    syndicates
    |> Enum.map(&deactivate_syndicate(&1, table))
    |> Enum.filter(fn res -> res != :ok end)
    |> case do
      [] -> :ok
      errors -> errors
    end
  end

  @spec activate_syndicates([Syndicate.t()], Persistence.table()) :: :ok | [{:error, any}]
  def activate_syndicates(syndicates, table \\ Persistence.default_table()) do
    syndicates
    |> Enum.map(&activate_syndicate(&1, table))
    |> Enum.filter(fn res -> res != :ok end)
    |> case do
      [] -> :ok
      errors -> errors
    end
  end

  @spec activate_syndicate(Syndicate.t(), Persistence.table()) :: :ok | {:error, any}
  def activate_syndicate(syndicate, table \\ Persistence.default_table()), do: set_syndicate(syndicate, true, table)

  @spec deactivate_syndicate(Syndicate.t(), Persistence.table()) :: :ok | {:error, any}
  def deactivate_syndicate(syndicate, table \\ Persistence.default_table()), do: set_syndicate(syndicate, false, table)

  @spec set_syndicate(Syndicate.t(), boolean(), Persistence.table()) :: :ok | {:error, any}
  defp set_syndicate(syndicate, value, table) do
    with {:ok, table_ref} <- table.recover.(table.name),
         {:ok, active_syndicates} <- table.get.(table_ref, :active_syndicates, nil),
         updated_active_syndicates = update_active_syndicates(active_syndicates, syndicate, value),
         {:ok, _table_ref} <- table.put.(table_ref, :active_syndicates, updated_active_syndicates) do
      :ok
    end
  end

  @spec update_active_syndicates([Syndicate.t()], Syndicate.t(), boolean()) :: MapSet.t()
  defp update_active_syndicates(active_syndicates, syndicate, value) do
    cond do
      is_nil(active_syndicates) and not value -> MapSet.new()
      is_nil(active_syndicates) -> MapSet.new() |> MapSet.put(syndicate)
      not value -> MapSet.delete(active_syndicates, syndicate)
      true -> MapSet.put(active_syndicates, syndicate)
    end
  end

  @spec syndicate_active?(Syndicate.t(), Persistence.table()) :: boolean()
  def syndicate_active?(syndicate, table \\ Persistence.default_table()) do
    with {:ok, table_ref} <- table.recover.(table.name),
         {:ok, active_syndicates} <-
           table.get.(table_ref, :active_syndicates, MapSet.new()) do
      MapSet.member?(active_syndicates, syndicate)
    else
      error ->
        Logger.error("Failed to run syndicate_active?: #{inspect(error)}")
        false
    end
  end

  @spec all_syndicates_active?(Persistence.table()) :: {:ok, boolean()} | {:error, any()}
  def all_syndicates_active?(table \\ Persistence.default_table()) do
    with {:ok, table_ref} <- table.recover.(table.name),
         {:ok, syndicates} <- table.get.(table_ref, :syndicates, []) do
      {:ok, Enum.all?(syndicates, &syndicate_active?(&1, table))}
    end
  end

  @spec get_active_syndicates(Persistence.table()) :: {:ok, [Syndicate.t()]} | {:error, any()}
  def get_active_syndicates(table \\ Persistence.default_table()) do
    with {:ok, table_ref} <- table.recover.(table.name),
         {:ok, syndicates} <- table.get.(table_ref, :active_syndicates, []) do
      {:ok, Enum.to_list(syndicates)}
    end
  end

  @spec get_inactive_syndicates(Persistence.table()) :: {:ok, [Syndicate.t()]} | {:error, any()}
  def get_inactive_syndicates(table \\ Persistence.default_table()) do
    with {:ok, table_ref} <- table.recover.(table.name),
         {:ok, all_syndicates} <- table.get.(table_ref, :syndicates, []),
         {:ok, active_syndicates} <- table.get.(table_ref, :active_syndicates, []) do
      {:ok, Enum.to_list(all_syndicates) -- Enum.to_list(active_syndicates)}
    end
  end

  @spec set_selected_active_syndicates([Syndicate.t()], Persistence.table()) :: :ok | {:error, any()}
  def set_selected_active_syndicates(syndicates, table \\ Persistence.default_table()) when is_list(syndicates),
    do: set_selection(syndicates, :active_syndicates, table)

  @spec get_selected_active_syndicates(Persistence.table()) :: {:ok, [Syndicate.t()]} | {:error, any()}
  def get_selected_active_syndicates(table \\ Persistence.default_table()), do: get_selection(:active_syndicates, table)

  @spec set_selected_inactive_syndicates([Syndicate.t()], Persistence.table()) :: :ok | {:error, any()}
  def set_selected_inactive_syndicates(syndicates, table \\ Persistence.default_table()) when is_list(syndicates),
    do: set_selection(syndicates, :inactive_syndicates, table)

  @spec get_selected_inactive_syndicates(Persistence.table()) :: {:ok, [Syndicate.t()]} | {:error, any()}
  def get_selected_inactive_syndicates(table \\ Persistence.default_table()) do
    get_selection(:inactive_syndicates, table)
  end

  @spec set_selection([Syndicate.t()], key(), Persistence.table()) :: :ok | {:error, any()}
  defp set_selection(syndicates, key, table) do
    with {:ok, table_ref} <- table.recover.(table.name),
         {:ok, _updated_table} <- table.put.(table_ref, String.to_atom("selected_#{key}"), syndicates) do
      :ok
    end
  end

  @spec get_selection(key(), Persistence.table()) :: {:ok, [Syndicate.t()]} | {:error, any()}
  defp get_selection(key, table) do
    case table.recover.(table.name) do
      {:ok, table_ref} -> table.get.(table_ref, String.to_atom("selected_#{key}"), [])
      err -> err
    end
  end
end
