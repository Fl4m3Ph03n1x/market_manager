defmodule WebInterface.Persistence.SyndicateTest do
  @moduledoc false

  use ExUnit.Case

  alias ETS
  alias Shared.Data.Syndicate
  alias WebInterface.Persistence.Syndicate, as: SyndicateStore

  setup_all do
    syndicates =
      Enum.sort([
        Syndicate.new(name: "Red Veil", id: :red_veil),
        Syndicate.new(name: "Perrin Sequence", id: :perrin_sequence),
        Syndicate.new(name: "New Loka", id: :new_loka),
        Syndicate.new(name: "Arbiters of Hexis", id: :arbiters_of_hexis),
        Syndicate.new(name: "Steel Meridian", id: :steel_meridian),
        Syndicate.new(name: "Cephalon Suda", id: :cephalon_suda),
        Syndicate.new(name: "Cephalon Simaris", id: :cephalon_simaris),
        Syndicate.new(name: "Arbitrations", id: :arbitrations)
      ])

    %{syndicates: syndicates}
  end

  describe "get_syndicates" do
    test "gets all syndicates", %{syndicates: syndicates} do
      {:ok, actual_syndicates} = SyndicateStore.get_syndicates()

      assert Enum.sort(actual_syndicates) == syndicates
    end
  end

  describe "get_all_syndicates_by_id" do
    test "get all syndicates by its ids", _data do
      {:ok, syndicates} = SyndicateStore.get_all_syndicates_by_id(["red_veil", "new_loka"])

      assert syndicates == [
               Syndicate.new(name: "Red Veil", id: :red_veil),
               Syndicate.new(name: "New Loka", id: :new_loka)
             ]
    end
  end

  describe "get_syndicate_by_id" do
    test "gets a syndicate by its id", _data do
      {:ok, syndicate} = SyndicateStore.get_syndicate_by_id("red_veil")
      assert syndicate == Syndicate.new(name: "Red Veil", id: :red_veil)
    end

    test "returns error if syndicate is not found" do
      assert {:error, :not_found} == SyndicateStore.get_syndicate_by_id("error")
    end
  end

  describe "activate_syndicate" do
    test "activates the given syndicate", _data do
      red_veil = Syndicate.new(name: "Red Veil", id: :red_veil)

      :ok = SyndicateStore.activate_syndicate(red_veil)
      {:ok, active_syndicates} = SyndicateStore.get_active_syndicates()

      assert active_syndicates == [red_veil]

      :ok = SyndicateStore.deactivate_syndicate(red_veil)
    end
  end

  describe "deactivate_syndicate" do
    test "deactivates the given syndicate", _data do
      red_veil = Syndicate.new(name: "Red Veil", id: :red_veil)
      :ok = SyndicateStore.activate_syndicate(red_veil)

      :ok = SyndicateStore.deactivate_syndicate(red_veil)
      {:ok, active_syndicates} = SyndicateStore.get_active_syndicates()

      assert active_syndicates == []
    end
  end

  describe "syndicate_active?" do
    test "returns whether or not a syndicate is active", _data do
      red_veil = Syndicate.new(name: "Red Veil", id: :red_veil)

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
      assert Enum.sort(inactive_syndicates) == Enum.sort(rest)

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
