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

  @spec syndicate_active?(atom) :: boolean()
  def syndicate_active?(syndicate_id) do
    with {:ok, table} <- ETS.KeyValueSet.wrap_existing(Persistence.table()),
         {:ok, true} <- ETS.KeyValueSet.get(table, syndicate_id) do
      true
    else
      _error -> false
    end
  end

  @spec all_syndicates_active? :: {:ok, boolean()} | {:error, any()}
  def all_syndicates_active? do
    with {:ok, table} <- ETS.KeyValueSet.wrap_existing(Persistence.table()),
         {:ok, syndicates} <- ETS.KeyValueSet.get(table, :syndicates) do
      {:ok,
       syndicates
       |> Enum.map(fn synd -> synd.id end)
       |> Enum.all?(&syndicate_active?/1)}
    end
  end

  @spec get_active_syndicates :: {:ok, [Syndicate.t()]} | {:error, any()}
  def get_active_syndicates do
    with {:ok, table} <- ETS.KeyValueSet.wrap_existing(Persistence.table()),
         {:ok, syndicates} <- ETS.KeyValueSet.get(table, :active_syndicates, []) do
      {:ok, Enum.to_list(syndicates)}
    end
  end

  @spec set_selected_syndicates([Syndicate.t()]) :: :ok | {:error, any()}
  def set_selected_syndicates(syndicates) do
    with {:ok, table} <- ETS.KeyValueSet.wrap_existing(Persistence.table()),
         {:ok, _updated_table} <- ETS.KeyValueSet.put(table, :selected_syndicates, syndicates) do
      :ok
    end
  end

  @spec get_selected_syndicates :: {:ok, [Syndicate.t()]} | {:error, any()}
  def get_selected_syndicates do
    case ETS.KeyValueSet.wrap_existing(Persistence.table()) do
      {:ok, table} -> ETS.KeyValueSet.get(table, :selected_syndicates, [])
      err -> err
    end
  end
end
