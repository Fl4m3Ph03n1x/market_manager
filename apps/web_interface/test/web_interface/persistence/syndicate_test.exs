defmodule WebInterface.Persistence.SyndicateTest do
  @moduledoc false

  use ExUnit.Case

  import ExUnit.CaptureLog

  alias Shared.Data.Syndicate
  alias WebInterface.Persistence.Syndicate, as: SyndicateStore

  defp by_id(%{id: id}), do: id

  setup do
    syndicates =
      [
        Syndicate.new(name: "Arbiters of Hexis", id: :arbiters_of_hexis, catalog: []),
        Syndicate.new(name: "Arbitrations", id: :arbitrations, catalog: []),
        Syndicate.new(name: "Cephalon Simaris", id: :cephalon_simaris, catalog: []),
        Syndicate.new(name: "Cephalon Suda", id: :cephalon_suda, catalog: []),
        Syndicate.new(name: "New Loka", id: :new_loka, catalog: []),
        Syndicate.new(name: "Perrin Sequence", id: :perrin_sequence, catalog: []),
        Syndicate.new(name: "Red Veil", id: :red_veil, catalog: []),
        Syndicate.new(name: "Steel Meridian", id: :steel_meridian, catalog: [])
      ]

    syndicate_ids = Enum.map(syndicates, &by_id/1)

    %{
      syndicates: syndicates,
      syndicate_ids: syndicate_ids,
      table: %{
        name: :data,
        recover: fn :data -> {:ok, :table_ref} end,
        get: fn :table_ref, :syndicates, _default -> {:ok, syndicates} end,
        put: fn :table_ref, _key, _val -> {:ok, :table_ref} end
      }
    }
  end

  describe "get_syndicates" do
    test "gets all syndicates", setup do
      assert SyndicateStore.get_syndicates(setup.table) == {:ok, setup.syndicates}
    end
  end

  describe "get_all_syndicates_by_id" do
    test "get all syndicates by its ids", setup do
      {:ok, syndicates} = SyndicateStore.get_all_syndicates_by_id(["red_veil", "new_loka"], setup.table)
      assert Enum.map(syndicates, &by_id/1) == [:new_loka, :red_veil]
    end
  end

  describe "get_syndicate_by_id" do
    test "gets a syndicate by its id", setup do
      {:ok, syndicate} = SyndicateStore.get_syndicate_by_id("red_veil", setup.table)
      assert syndicate.id == :red_veil
    end

    test "returns error if syndicate is not found", setup do
      assert {:error, :not_found} == SyndicateStore.get_syndicate_by_id("error", setup.table)
    end
  end

  describe "activate_syndicates" do
    test "activates the given syndicates", setup do
      table =
        Map.merge(setup.table, %{
          get: fn :table_ref, :active_syndicates, nil -> {:ok, nil} end,
          put: fn
            :table_ref, :active_syndicates, data ->
              result =
                cond do
                  data == MapSet.new([%Syndicate{catalog: [], id: :new_loka, name: "New Loka"}]) -> true
                  data == MapSet.new([%Syndicate{catalog: [], id: :red_veil, name: "Red Veil"}]) -> true
                  true -> false
                end

              assert result

              {:ok, :table_ref}
          end
        })

      red_veil = Syndicate.new(name: "Red Veil", id: :red_veil, catalog: [])
      new_loka = Syndicate.new(name: "New Loka", id: :new_loka, catalog: [])

      assert SyndicateStore.activate_syndicates([red_veil, new_loka], table) == :ok
    end
  end

  describe "activate_syndicate" do
    test "activates the given syndicate", setup do
      table =
        Map.merge(setup.table, %{
          get: fn :table_ref, :active_syndicates, nil -> {:ok, nil} end,
          put: fn
            :table_ref, :active_syndicates, data ->
              result =
                if data == MapSet.new([%Syndicate{catalog: [], id: :red_veil, name: "Red Veil"}]) do
                  true
                else
                  false
                end

              assert result

              {:ok, :table_ref}
          end
        })

      red_veil = Syndicate.new(name: "Red Veil", id: :red_veil, catalog: [])

      assert SyndicateStore.activate_syndicate(red_veil, table) == :ok
    end
  end

  describe "deactivate_syndicate" do
    test "deactivates the given syndicate", setup do
      table =
        Map.merge(setup.table, %{
          get: fn :table_ref, :active_syndicates, nil ->
            {:ok, MapSet.new([%Syndicate{catalog: [], id: :red_veil, name: "Red Veil"}])}
          end,
          put: fn
            :table_ref, :active_syndicates, data ->
              assert data == MapSet.new()
              {:ok, :table_ref}
          end
        })

      red_veil = Syndicate.new(name: "Red Veil", id: :red_veil, catalog: [])
      assert SyndicateStore.deactivate_syndicate(red_veil, table) == :ok
    end
  end

  describe "syndicate_active?" do
    test "returns whether or not a syndicate is active", setup do
      table =
        Map.merge(setup.table, %{
          get: fn :table_ref, :active_syndicates, _mapset ->
            {:ok, MapSet.new([%Syndicate{catalog: [], id: :red_veil, name: "Red Veil"}])}
          end
        })

      red_veil = Syndicate.new(name: "Red Veil", id: :red_veil, catalog: [])

      assert SyndicateStore.syndicate_active?(red_veil, table)
    end

    test "logs error if access to memory fails", setup do
      table =
        Map.merge(setup.table, %{
          get: fn :table_ref, :active_syndicates, _mapset ->
            {:error, :invalid_table}
          end
        })

      red_veil = Syndicate.new(name: "Red Veil", id: :red_veil, catalog: [])

      assert capture_log(fn -> refute SyndicateStore.syndicate_active?(red_veil, table) end) =~
               "Failed to run syndicate_active?"
    end
  end

  describe "all_syndicates_active?" do
    test "returns whether or not all syndicates are active", setup do
      table =
        Map.merge(setup.table, %{
          get: fn
            :table_ref, :syndicates, [] ->
              {:ok, setup.syndicates}

            :table_ref, :active_syndicates, _mapset ->
              {:ok,
               MapSet.new([
                 %Syndicate{name: "Red Veil", id: :red_veil, catalog: []},
                 %Syndicate{name: "Perrin Sequence", id: :perrin_sequence, catalog: []},
                 %Syndicate{name: "New Loka", id: :new_loka, catalog: []},
                 %Syndicate{name: "Arbiters of Hexis", id: :arbiters_of_hexis, catalog: []},
                 %Syndicate{name: "Steel Meridian", id: :steel_meridian, catalog: []},
                 %Syndicate{name: "Cephalon Suda", id: :cephalon_suda, catalog: []},
                 %Syndicate{name: "Cephalon Simaris", id: :cephalon_simaris, catalog: []},
                 %Syndicate{name: "Arbitrations", id: :arbitrations, catalog: []}
               ])}
          end
        })

      assert {:ok, true} == SyndicateStore.all_syndicates_active?(table)
    end
  end

  describe "get_active_syndicates" do
    test "returns active syndicates", setup do
      table =
        Map.merge(setup.table, %{
          get: fn :table_ref, :active_syndicates, [] -> {:ok, MapSet.new(setup.syndicates)} end
        })

      {:ok, active_syndicates} = SyndicateStore.get_active_syndicates(table)
      assert active_syndicates == setup.syndicates
    end
  end

  describe "get_inactive_syndicates" do
    test "returns inactive syndicates", setup do
      table =
        Map.merge(setup.table, %{
          get: fn
            :table_ref, :syndicates, [] ->
              {:ok, setup.syndicates}

            :table_ref, :active_syndicates, [] ->
              {:ok,
               MapSet.new([
                 Syndicate.new(name: "Arbiters of Hexis", id: :arbiters_of_hexis, catalog: []),
                 Syndicate.new(name: "Arbitrations", id: :arbitrations, catalog: []),
                 Syndicate.new(name: "Cephalon Simaris", id: :cephalon_simaris, catalog: []),
                 Syndicate.new(name: "Cephalon Suda", id: :cephalon_suda, catalog: []),
                 Syndicate.new(name: "New Loka", id: :new_loka, catalog: []),
                 Syndicate.new(name: "Perrin Sequence", id: :perrin_sequence, catalog: []),
                 Syndicate.new(name: "Red Veil", id: :red_veil, catalog: [])
               ])}
          end
        })

      {:ok, inactive_syndicates} = SyndicateStore.get_inactive_syndicates(table)
      assert Enum.map(inactive_syndicates, &by_id/1) == [:steel_meridian]
    end
  end

  describe "set_selected_active_syndicates" do
    test "sets selected syndicates in Activate tab", setup do
      syndicate =
        Syndicate.new(name: "Red Veil", id: :red_veil, catalog: [])

      table =
        Map.merge(setup.table, %{
          put: fn
            :table_ref, :selected_active_syndicates, [^syndicate] -> {:ok, :table_ref}
          end
        })

      assert :ok == SyndicateStore.set_selected_active_syndicates([syndicate], table)
    end
  end

  describe "get_selected_active_syndicates" do
    test "gets selected syndicates in Activate tab", setup do
      table =
        Map.merge(setup.table, %{
          get: fn
            :table_ref, :selected_active_syndicates, [] -> {:ok, setup.syndicates}
          end
        })

      {:ok, selected_syndicates} = SyndicateStore.get_selected_active_syndicates(table)

      assert selected_syndicates == setup.syndicates
    end
  end

  describe "set_selected_inactive_syndicates" do
    test "sets selected syndicates in Deactivate tab", setup do
      syndicate =
        Syndicate.new(name: "Red Veil", id: :red_veil, catalog: [])

      table =
        Map.merge(setup.table, %{
          put: fn
            :table_ref, :selected_inactive_syndicates, [^syndicate] -> {:ok, :table_ref}
          end
        })

      assert :ok == SyndicateStore.set_selected_inactive_syndicates([syndicate], table)
    end
  end

  describe "get_selected_inactive_syndicates" do
    test "gets selected syndicates in Deactivate tab", setup do
      table =
        Map.merge(setup.table, %{
          get: fn
            :table_ref, :selected_inactive_syndicates, [] -> {:ok, setup.syndicates}
          end
        })

      {:ok, selected_syndicates} = SyndicateStore.get_selected_inactive_syndicates(table)

      assert selected_syndicates == setup.syndicates
    end
  end
end
