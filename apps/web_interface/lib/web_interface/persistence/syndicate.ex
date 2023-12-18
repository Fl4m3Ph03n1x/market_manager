defmodule WebInterface.Persistence.Syndicate do
  @moduledoc """
  Persistence module for syndicate data. Mostly to track selected options in the menu and access the list of syndicates.
  """

  alias ETS
  alias Shared.Data.Syndicate
  alias WebInterface.Persistence

  @spec get_syndicates :: {:ok, [Syndicate.t()]} | {:error, any}
  def get_syndicates do
    with {:ok, table} <- ETS.KeyValueSet.wrap_existing(Persistence.table()) do
      ETS.KeyValueSet.get(table, :syndicates)
    end
  end

  @spec get_all_syndicates_by_id([String.t()]) :: {:ok, [Syndicate.t()]} | {:error, any}
  def get_all_syndicates_by_id(ids) do
    valid_ids = Enum.filter(ids, fn id -> id != "" end)

    with {:ok, table} <- ETS.KeyValueSet.wrap_existing(Persistence.table()),
         {:ok, syndicates} <- ETS.KeyValueSet.get(table, :syndicates) do
      all_syndicates =
        for syndicate <- syndicates,
            id <- valid_ids,
            syndicate.id == String.to_existing_atom(id),
            do: syndicate

      {:ok, all_syndicates}
    end
  end

  @spec get_syndicate_by_id(String.t()) :: {:ok, Syndicate.t()} | {:error, any}
  def get_syndicate_by_id(id) do
    with {:ok, table} <- ETS.KeyValueSet.wrap_existing(Persistence.table()),
         {:ok, syndicates} <- ETS.KeyValueSet.get(table, :syndicates) do
      syndicates
      |> Enum.find(fn syndicate -> syndicate.id == String.to_existing_atom(id) end)
      |> case do
        nil -> {:error, :not_found}
        syndicate -> {:ok, syndicate}
      end
    end
  end

  @spec activate_syndicates([Syndicate.t()]) :: :ok | [{:error, any}]
  def activate_syndicates(syndicates) do
    syndicates
    |> Enum.map(&activate_syndicate(&1))
    |> Enum.filter(fn res -> res != :ok end)
    |> case do
      [] -> :ok
      errors -> errors
    end
  end

  @spec activate_syndicate(Syndicate.t()) :: :ok | {:error, any}
  def activate_syndicate(syndicate), do: set_syndicate(syndicate, true)

  @spec deactivate_syndicate(Syndicate.t()) :: :ok | {:error, any}
  def deactivate_syndicate(syndicate), do: set_syndicate(syndicate, false)

  @spec set_syndicate(Syndicate.t(), boolean) :: :ok | {:error, any}
  defp set_syndicate(syndicate, value) do
    with {:ok, table} <- ETS.KeyValueSet.wrap_existing(Persistence.table()),
         {:ok, active_syndicates} <- ETS.KeyValueSet.get(table, :active_syndicates, nil),
         updated_active_syndicates =
           update_active_syndicates(active_syndicates, syndicate, value),
         {:ok, _table} <-
           ETS.KeyValueSet.put(table, :active_syndicates, updated_active_syndicates) do
      :ok
    end
  end

  @spec update_active_syndicates([Syndicate.t()], Syndicate.t(), boolean) :: MapSet.t()
  defp update_active_syndicates(active_syndicates, syndicate, value) do
    cond do
      is_nil(active_syndicates) and not value -> MapSet.new()
      is_nil(active_syndicates) -> MapSet.new() |> MapSet.put(syndicate)
      not value -> MapSet.delete(active_syndicates, syndicate)
      true -> MapSet.put(active_syndicates, syndicate)
    end
  end

  @spec syndicate_active?(Syndicate.t()) :: boolean()
  def syndicate_active?(syndicate) do
    with {:ok, table} <- ETS.KeyValueSet.wrap_existing(Persistence.table()),
         {:ok, active_syndicates} <- ETS.KeyValueSet.get(table, :active_syndicates, MapSet.new()) do
      MapSet.member?(active_syndicates, syndicate)
    else
      _error -> false
    end
  end

  @spec all_syndicates_active? :: {:ok, boolean()} | {:error, any()}
  def all_syndicates_active? do
    with {:ok, table} <- ETS.KeyValueSet.wrap_existing(Persistence.table()),
         {:ok, syndicates} <- ETS.KeyValueSet.get(table, :syndicates) do
      {:ok, Enum.all?(syndicates, &syndicate_active?/1)}
    end
  end

  @spec get_active_syndicates :: {:ok, [Syndicate.t()]} | {:error, any()}
  def get_active_syndicates do
    with {:ok, table} <- ETS.KeyValueSet.wrap_existing(Persistence.table()),
         {:ok, syndicates} <- ETS.KeyValueSet.get(table, :active_syndicates, []) do
      {:ok, Enum.to_list(syndicates)}
    end
  end

  @spec get_inactive_syndicates :: {:ok, [Syndicate.t()]} | {:error, any()}
  def get_inactive_syndicates do
    with {:ok, table} <- ETS.KeyValueSet.wrap_existing(Persistence.table()),
         {:ok, all_syndicates} <- ETS.KeyValueSet.get(table, :syndicates),
         {:ok, active_syndicates} <- ETS.KeyValueSet.get(table, :active_syndicates, []) do
      {:ok, Enum.to_list(all_syndicates) -- Enum.to_list(active_syndicates)}
    end
  end

  @spec set_selected_active_syndicates([Syndicate.t()]) :: :ok | {:error, any()}
  def set_selected_active_syndicates(syndicates) when is_list(syndicates) do
    set_selection(syndicates, :active_syndicates)
  end

  @spec get_selected_active_syndicates :: {:ok, [Syndicate.t()]} | {:error, any()}
  def get_selected_active_syndicates, do: get_selection(:active_syndicates)

  @spec set_selected_inactive_syndicates([Syndicate.t()]) :: :ok | {:error, any()}
  def set_selected_inactive_syndicates(syndicates) when is_list(syndicates) do
    set_selection(syndicates, :inactive_syndicates)
  end

  @spec get_selected_inactive_syndicates :: {:ok, [Syndicate.t()]} | {:error, any()}
  def get_selected_inactive_syndicates, do: get_selection(:inactive_syndicates)

  @spec set_selection([Syndicate.t()], key :: atom) :: :ok | {:error, any()}
  defp set_selection(syndicates, key) do
    with {:ok, table} <- ETS.KeyValueSet.wrap_existing(Persistence.table()),
         {:ok, _updated_table} <-
           ETS.KeyValueSet.put(table, String.to_atom("selected_#{key}"), syndicates) do
      :ok
    end
  end

  @spec get_selection(key :: atom) :: {:ok, [Syndicate.t()]} | {:error, any()}
  defp get_selection(key) do
    case ETS.KeyValueSet.wrap_existing(Persistence.table()) do
      {:ok, table} -> ETS.KeyValueSet.get(table, String.to_atom("selected_#{key}"), [])
      err -> err
    end
  end
end
