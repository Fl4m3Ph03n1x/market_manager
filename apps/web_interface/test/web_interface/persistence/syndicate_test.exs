defmodule WebInterface.Persistence.SyndicateTest do
  @moduledoc false

  use ExUnit.Case

  alias ETS
  alias Shared.Data.Syndicate
  alias WebInterface.Persistence.Syndicate, as: SyndicateStore

  defp by_id(%{id: id}), do: id

  setup_all do
    syndicates =
      [
        Syndicate.new(name: "Red Veil", id: :red_veil, catalog: []),
        Syndicate.new(name: "Perrin Sequence", id: :perrin_sequence, catalog: []),
        Syndicate.new(name: "New Loka", id: :new_loka, catalog: []),
        Syndicate.new(name: "Arbiters of Hexis", id: :arbiters_of_hexis, catalog: []),
        Syndicate.new(name: "Steel Meridian", id: :steel_meridian, catalog: []),
        Syndicate.new(name: "Cephalon Suda", id: :cephalon_suda, catalog: []),
        Syndicate.new(name: "Cephalon Simaris", id: :cephalon_simaris, catalog: []),
        Syndicate.new(name: "Arbitrations", id: :arbitrations, catalog: [])
      ]
      |> Enum.sort()

    syndicate_ids =
      syndicates
      |> Enum.map(&by_id/1)
      |> Enum.sort()

    %{syndicates: syndicates, syndicate_ids: syndicate_ids}
  end

  describe "get_syndicates" do
    test "gets all syndicates", %{syndicate_ids: syndicate_ids} do
      {:ok, actual_syndicates} = SyndicateStore.get_syndicates()

      sorted_syndicates =
        actual_syndicates
        |> Enum.map(&by_id/1)
        |> Enum.sort()

      assert sorted_syndicates == syndicate_ids
    end
  end

  describe "get_all_syndicates_by_id" do
    test "get all syndicates by its ids", _data do
      {:ok, syndicates} = SyndicateStore.get_all_syndicates_by_id(["red_veil", "new_loka"])

      sorted_syndicates = Enum.map(syndicates, &by_id/1)

      assert sorted_syndicates == [:red_veil, :new_loka]
    end
  end

  describe "get_syndicate_by_id" do
    test "gets a syndicate by its id", _data do
      {:ok, syndicate} = SyndicateStore.get_syndicate_by_id("red_veil")
      assert syndicate.id == :red_veil
    end

    test "returns error if syndicate is not found" do
      assert {:error, :not_found} == SyndicateStore.get_syndicate_by_id("error")
    end
  end

  describe "activate_syndicates" do
    test "activates the given syndicates", _data do
      red_veil = Syndicate.new(name: "Red Veil", id: :red_veil, catalog: [])
      new_loka = Syndicate.new(name: "New Loka", id: :new_loka, catalog: [])

      :ok = SyndicateStore.activate_syndicates([red_veil, new_loka])
      {:ok, active_syndicates} = SyndicateStore.get_active_syndicates()

      assert active_syndicates |> Enum.sort() |> Enum.map(&by_id/1) == [:new_loka, :red_veil]

      :ok = SyndicateStore.deactivate_syndicate(red_veil)
      :ok = SyndicateStore.deactivate_syndicate(new_loka)
    end
  end

  describe "activate_syndicate" do
    test "activates the given syndicate", _data do
      red_veil = Syndicate.new(name: "Red Veil", id: :red_veil, catalog: [])

      :ok = SyndicateStore.activate_syndicate(red_veil)
      {:ok, active_syndicates} = SyndicateStore.get_active_syndicates()

      assert active_syndicates == [red_veil]

      :ok = SyndicateStore.deactivate_syndicate(red_veil)
    end
  end

  describe "deactivate_syndicate" do
    test "deactivates the given syndicate", _data do
      red_veil = Syndicate.new(name: "Red Veil", id: :red_veil, catalog: [])
      :ok = SyndicateStore.activate_syndicate(red_veil)

      :ok = SyndicateStore.deactivate_syndicate(red_veil)
      {:ok, active_syndicates} = SyndicateStore.get_active_syndicates()

      assert active_syndicates == []
    end
  end

  describe "syndicate_active?" do
    test "returns whether or not a syndicate is active", _data do
      red_veil = Syndicate.new(name: "Red Veil", id: :red_veil, catalog: [])

      :ok = SyndicateStore.activate_syndicate(red_veil)

      assert SyndicateStore.syndicate_active?(red_veil)

      :ok = SyndicateStore.deactivate_syndicate(red_veil)
    end
  end

  describe "all_syndicates_active?" do
    test "returns whether or not all syndicates are active", %{syndicates: syndicates} do
      Enum.each(syndicates, fn syndicate -> SyndicateStore.activate_syndicate(syndicate) end)

      assert SyndicateStore.all_syndicates_active?()

      Enum.each(syndicates, fn syndicate -> SyndicateStore.deactivate_syndicate(syndicate) end)
    end
  end

  describe "get_active_syndicates" do
    test "returns active syndicates", %{syndicates: syndicates} do
      Enum.each(syndicates, fn syndicate -> SyndicateStore.activate_syndicate(syndicate) end)

      {:ok, active_syndicates} = SyndicateStore.get_active_syndicates()
      assert Enum.sort(active_syndicates) == Enum.sort(syndicates)

      Enum.each(syndicates, fn syndicate -> SyndicateStore.deactivate_syndicate(syndicate) end)
    end
  end

  describe "get_inactive_syndicates" do
    test "returns inactive syndicates", %{syndicates: [active_syndicate | rest]} do
      SyndicateStore.activate_syndicate(active_syndicate)

      {:ok, inactive_syndicates} = SyndicateStore.get_inactive_syndicates()
      assert inactive_syndicates |> Enum.map(&by_id/1)  |> Enum.sort() == rest |> Enum.map(&by_id/1) |> Enum.sort()

      SyndicateStore.deactivate_syndicate(active_syndicate)
    end
  end

  describe "set_selected_active_syndicates && get_selected_active_syndicates" do
    test "sets and gets selected syndicates in Activate tab", %{syndicates: [syndicate | _rest]} do
      :ok = SyndicateStore.set_selected_active_syndicates([syndicate])
      {:ok, selected_syndicates} = SyndicateStore.get_selected_active_syndicates()
      assert selected_syndicates == [syndicate]

      :ok = SyndicateStore.set_selected_active_syndicates([])
    end
  end

  describe "set_selected_inactive_syndicates && get_selected_inactive_syndicates" do
    test "sets and gets selected syndicates in Deactivate tab", %{syndicates: [syndicate | _rest]} do
      :ok = SyndicateStore.set_selected_inactive_syndicates([syndicate])
      {:ok, selected_syndicates} = SyndicateStore.get_selected_inactive_syndicates()
      assert selected_syndicates == [syndicate]

      :ok = SyndicateStore.set_selected_inactive_syndicates([])
    end
  end
end
