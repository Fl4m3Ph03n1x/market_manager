defmodule WebInterface.ActivateLiveTest do
  @moduledoc false

  use WebInterface.ConnCase, async: false

  import Phoenix.LiveViewTest
  import Mock

  alias Manager
  alias Shared.Data.{Strategy, Syndicate, User}
  alias WebInterface.Persistence.Strategy, as: StrategyStore
  alias WebInterface.Persistence.Syndicate, as: SyndicateStore
  alias WebInterface.Persistence.User, as: UserStore

  setup do
    user = User.new(ingame_name: "Fl4m3", slug: "fl4m3", patreon?: false)

    strategies =
      [
        Strategy.new(
          name: "Top 3 Average",
          id: :top_three_average,
          description: "Gets the 3 lowest prices for the given item and calculates the average."
        ),
        Strategy.new(
          name: "Top 5 Average",
          id: :top_five_average,
          description: "Gets the 5 lowest prices for the given item and calculates the average."
        ),
        Strategy.new(
          name: "Equal to lowest",
          id: :equal_to_lowest,
          description: "Gets the lowest price for the given item and uses it."
        ),
        Strategy.new(
          name: "Lowest minus one",
          id: :lowest_minus_one,
          description: "Gets the lowest price for the given item and beats it by 1."
        )
      ]

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

    %{user: user, strategies: strategies, syndicates: syndicates}
  end

  describe "frontend events" do
    test "it executes activate command when button is pressed", %{
      conn: conn,
      user: user,
      strategies: strategies,
      syndicates: syndicates
    } do
      with_mocks([
        {UserStore, [], [get_user: fn -> {:ok, user} end, has_user?: fn -> true end]},
        {StrategyStore, [],
         [
           get_strategies: fn -> {:ok, strategies} end,
           get_selected_strategy: fn ->
             {:ok, Enum.find(strategies, fn strategy -> strategy.id == :lowest_minus_one end)}
           end,
           get_strategy_by_id: fn id ->
             strategies
             |> Enum.find(&(&1.id == String.to_existing_atom(id)))
             |> then(&{:ok, &1})
           end
         ]},
        {SyndicateStore, [],
         [
           get_syndicates: fn -> {:ok, syndicates} end,
           get_active_syndicates: fn -> {:ok, []} end,
           get_selected_active_syndicates: fn ->
             {:ok, Enum.filter(syndicates, fn syndicate -> syndicate.id == :steel_meridian end)}
           end,
           get_all_syndicates_by_id: fn ids ->
             syndicates
             |> Enum.filter(fn syndicate -> syndicate.id in Enum.map(ids, &String.to_existing_atom/1) end)
             |> then(&{:ok, &1})
           end
         ]},
        {Manager, [], [activate: fn _params -> :ok end]}
      ]) do
        strategy_id = Atom.to_string(:lowest_minus_one)
        syndicate_id = Atom.to_string(:steel_meridian)

        {:ok, view, _html} = live(conn, ~p"/activate")

        html =
          view
          |> form("form", %{"strategy" => strategy_id, "syndicates" => [syndicate_id]})
          |> render_submit()

        assert_called(UserStore.get_user())
        assert_called(UserStore.has_user?())

        assert_called(StrategyStore.get_strategies())
        assert_called(StrategyStore.get_selected_strategy())
        assert_called(StrategyStore.get_strategy_by_id(strategy_id))

        assert_called(SyndicateStore.get_syndicates())
        assert_called(SyndicateStore.get_active_syndicates())
        assert_called(SyndicateStore.get_selected_active_syndicates())
        assert_called(SyndicateStore.get_all_syndicates_by_id([syndicate_id]))

        assert_called(Manager.activate(%{steel_meridian: :lowest_minus_one}))
        assert html =~ "Activation in progress..."
      end
    end

    test "it changes syndicates correctly", %{
      conn: conn,
      user: user,
      strategies: strategies,
      syndicates: syndicates
    } do
      active_syndicates = Enum.filter(syndicates, fn syndicate -> syndicate.id == :red_veil end)

      with_mocks([
        {UserStore, [], [get_user: fn -> {:ok, user} end, has_user?: fn -> true end]},
        {StrategyStore, [],
         [
           get_strategies: fn -> {:ok, strategies} end,
           get_selected_strategy: fn -> {:ok, nil} end
         ]},
        {SyndicateStore, [],
         [
           get_syndicates: fn -> {:ok, syndicates} end,
           get_active_syndicates: fn -> {:ok, active_syndicates} end,
           get_selected_active_syndicates: fn -> {:ok, []} end,
           get_all_syndicates_by_id: fn ids ->
             syndicates
             |> Enum.filter(fn syndicate -> syndicate.id in Enum.map(ids, &String.to_existing_atom/1) end)
             |> then(&{:ok, &1})
           end,
           set_selected_active_syndicates: fn _syndicates -> :ok end
         ]}
      ]) do
        change_selected_syndicates = Enum.filter(syndicates, fn syndicate -> syndicate.id == :steel_meridian end)
        change_syndicate_ids = Enum.map(change_selected_syndicates, fn syndicate -> Atom.to_string(syndicate.id) end)

        {:ok, view, _html} = live(conn, ~p"/activate")

        view
        |> form("form", %{"syndicates" => change_syndicate_ids})
        |> render_change(%{_target: ["syndicates"]})

        assert_called(UserStore.get_user())
        assert_called(UserStore.has_user?())

        assert_called(StrategyStore.get_strategies())
        assert_called(StrategyStore.get_selected_strategy())

        assert_called(SyndicateStore.get_syndicates())
        assert_called(SyndicateStore.get_active_syndicates())
        assert_called(SyndicateStore.get_selected_active_syndicates())
        assert_called(SyndicateStore.get_all_syndicates_by_id(change_syndicate_ids))
        assert_called(SyndicateStore.set_selected_active_syndicates(change_selected_syndicates ++ active_syndicates))

        assert has_element?(view, "input#steel_meridian[checked]")
        assert has_element?(view, "input#red_veil[checked][disabled]")
      end
    end

    test "it changes strategy correctly", %{
      conn: conn,
      user: user,
      strategies: strategies,
      syndicates: syndicates
    } do
      with_mocks([
        {UserStore, [], [get_user: fn -> {:ok, user} end, has_user?: fn -> true end]},
        {StrategyStore, [],
         [
           get_strategies: fn -> {:ok, strategies} end,
           get_selected_strategy: fn -> {:ok, nil} end,
           get_strategy_by_id: fn id ->
             strategies
             |> Enum.find(&(&1.id == String.to_existing_atom(id)))
             |> then(&{:ok, &1})
           end,
           set_selected_strategy: fn _strategy -> :ok end
         ]},
        {SyndicateStore, [],
         [
           get_syndicates: fn -> {:ok, syndicates} end,
           get_active_syndicates: fn -> {:ok, []} end,
           get_selected_active_syndicates: fn -> {:ok, []} end
         ]}
      ]) do
        strategy = Enum.find(strategies, fn strategy -> strategy.id == :lowest_minus_one end)
        change_strategy_id = Atom.to_string(:lowest_minus_one)

        {:ok, view, _html} = live(conn, ~p"/activate")

        view
        |> form("form", %{"strategy" => change_strategy_id})
        |> render_change()

        assert_called(UserStore.get_user())
        assert_called(UserStore.has_user?())

        assert_called(SyndicateStore.get_syndicates())
        assert_called(SyndicateStore.get_active_syndicates())
        assert_called(SyndicateStore.get_selected_active_syndicates())

        assert_called(StrategyStore.get_strategies())
        assert_called(StrategyStore.get_selected_strategy())
        assert_called(StrategyStore.get_strategy_by_id(change_strategy_id))
        assert_called(StrategyStore.set_selected_strategy(strategy))

        assert has_element?(view, "input#lowest_minus_one[checked]")
      end
    end
  end

  describe "backend events" do
  end
end
