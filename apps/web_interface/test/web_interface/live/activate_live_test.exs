defmodule WebInterface.ActivateLiveTest do
  @moduledoc false

  use WebInterface.ConnCase, async: false

  import ExUnit.CaptureLog
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
    setup_with_mocks([
      {UserStore, [], [get_user: fn -> {:ok, user} end, has_user?: fn -> true end]}
    ], %{user: user}) do
      :ok
    end

    test "it executes activate command when button is pressed", %{
      conn: conn,
      strategies: strategies,
      syndicates: syndicates
    } do
      with_mocks([
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

        assert_called_exactly(StrategyStore.get_strategy_by_id(strategy_id), 1)
        assert_called_exactly(SyndicateStore.get_all_syndicates_by_id([syndicate_id]), 1)
        assert_called_exactly(Manager.activate(%{steel_meridian: :lowest_minus_one}), 1)
        assert html =~ "Activation in progress..."
      end
    end

    test "it shows error if execute fails", %{
      conn: conn,
      strategies: strategies,
      syndicates: syndicates
    } do
      with_mocks([
        {StrategyStore, [],
         [
           get_strategies: fn -> {:ok, strategies} end,
           get_selected_strategy: fn ->
             {:ok, Enum.find(strategies, fn strategy -> strategy.id == :lowest_minus_one end)}
           end,
           get_strategy_by_id: fn _id -> {:error, :not_found} end
         ]},
        {SyndicateStore, [],
         [
           get_syndicates: fn -> {:ok, syndicates} end,
           get_active_syndicates: fn -> {:ok, []} end,
           get_selected_active_syndicates: fn ->
             {:ok, Enum.filter(syndicates, fn syndicate -> syndicate.id == :steel_meridian end)}
           end
         ]},
        {Manager, [], [activate: fn _params -> :ok end]}
      ]) do
        strategy_id = Atom.to_string(:lowest_minus_one)
        syndicate_id = Atom.to_string(:steel_meridian)

        {:ok, view, _html} = live(conn, ~p"/activate")

        log =
          capture_log(fn ->
            view
            |> form("form", %{"strategy" => strategy_id, "syndicates" => [syndicate_id]})
            |> render_submit()
          end)

        assert_called_exactly(StrategyStore.get_strategy_by_id(strategy_id), 1)

        assert_not_called(SyndicateStore.get_all_syndicates_by_id(:_))
        assert_not_called(Manager.activate(:_))
        
        assert render(view) =~ "Unable to perform activation! Please check the logs for details."
        assert log =~ "Unable to retrieve data: {:error, :not_found}"
      end
    end

    test "it changes syndicates correctly", %{
      conn: conn,
      strategies: strategies,
      syndicates: syndicates
    } do
      active_syndicates = Enum.filter(syndicates, fn syndicate -> syndicate.id == :red_veil end)

      with_mocks([
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

        assert_called_exactly(SyndicateStore.get_all_syndicates_by_id(change_syndicate_ids), 1)
        assert_called_exactly(
          SyndicateStore.set_selected_active_syndicates(change_selected_syndicates ++ active_syndicates),
          1
        )

        assert has_element?(view, "input#steel_meridian[checked]")
        assert has_element?(view, "input#red_veil[checked][disabled]")
      end
    end

    test "it shows error if changing syndicates fails", %{
      conn: conn,
      strategies: strategies,
      syndicates: syndicates
    } do
      selected_syndicates = Enum.filter(syndicates, fn syndicate -> syndicate.id == :perrin_sequence end)

      with_mocks([
        {StrategyStore, [],
         [
           get_strategies: fn -> {:ok, strategies} end,
           get_selected_strategy: fn -> {:ok, nil} end
         ]},
        {SyndicateStore, [],
         [
           get_syndicates: fn -> {:ok, syndicates} end,
           get_active_syndicates: fn -> {:ok, []} end,
           get_selected_active_syndicates: fn -> {:ok, selected_syndicates} end,
           get_all_syndicates_by_id: fn _ids -> {:error, :not_found} end,
           set_selected_active_syndicates: fn _syndicates -> :ok end
         ]}
      ]) do
        change_syndicate_ids = [Atom.to_string(:steel_meridian)]
        
        {:ok, view, _html} = live(conn, ~p"/activate")

        log =
          capture_log(fn ->
            view
            |> form("form", %{"syndicates" => change_syndicate_ids})
            |> render_change(%{_target: ["syndicates"]})
          end)

        assert_called_exactly(SyndicateStore.get_all_syndicates_by_id(change_syndicate_ids), 1)
        assert_not_called(SyndicateStore.set_selected_active_syndicates(:_))

        assert render(view) =~ "Unable to perform activation! Please check the logs for details."
        assert log =~ "Unable to retrieve syndicate data: {:error, :not_found}"

        assert has_element?(view, "input#perrin_sequence[checked]")
        refute has_element?(view, "input#steel_meridian[checked]")
      end
    end

    test "it changes strategy correctly", %{
      conn: conn,
      strategies: strategies,
      syndicates: syndicates
    } do
      with_mocks([
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

        assert_called_exactly(StrategyStore.get_strategy_by_id(change_strategy_id), 1)
        assert_called_exactly(StrategyStore.set_selected_strategy(strategy), 1)

        assert has_element?(view, "input#lowest_minus_one[checked]")
      end
    end

    test "it shows error if changing strategy fails", %{
      conn: conn,
      strategies: strategies,
      syndicates: syndicates
    } do
      selected_strategy = Enum.find(strategies, fn strategy -> strategy.id == :top_three_average end)

      with_mocks([
        {StrategyStore, [],
         [
           get_strategies: fn -> {:ok, strategies} end,
           get_selected_strategy: fn -> {:ok, selected_strategy} end,
           get_strategy_by_id: fn _id -> {:error, :not_found} end,
           set_selected_strategy: fn _strategy -> :ok end
         ]},
        {SyndicateStore, [],
         [
           get_syndicates: fn -> {:ok, syndicates} end,
           get_active_syndicates: fn -> {:ok, []} end,
           get_selected_active_syndicates: fn -> {:ok, []} end
         ]}
      ]) do
        change_strategy_id = Atom.to_string(:lowest_minus_one)

        {:ok, view, _html} = live(conn, ~p"/activate")

        log =
          capture_log(fn ->
            view
            |> form("form", %{"strategy" => change_strategy_id})
            |> render_change(%{_target: ["strategy"]})
          end)

        assert_called_exactly(StrategyStore.get_strategy_by_id(change_strategy_id), 1)
        assert_not_called(StrategyStore.set_selected_strategy(:_))

        assert render(view) =~ "Unable to retrieve data!"
        assert log =~ "Unable to retrieve strategy data: {:error, :not_found}"

        assert has_element?(view, "input#top_three_average[checked]")
        refute has_element?(view, "input#lowest_minus_one[checked]")
      end
    end
  end

  describe "backend events" do
    test "it loads activation data on mount", %{
      conn: conn,
      user: user,
      strategies: strategies,
      syndicates: syndicates
    } do
      selected_strategy = Enum.find(strategies, fn strategy -> strategy.id == :lowest_minus_one end)
      active_syndicates = Enum.filter(syndicates, fn syndicate -> syndicate.id == :red_veil end)

      with_mocks([
        {UserStore, [], [get_user: fn -> {:ok, user} end, has_user?: fn -> true end]},
        {StrategyStore, [],
         [
           get_strategies: fn -> {:ok, strategies} end,
           get_selected_strategy: fn -> {:ok, selected_strategy} end
         ]},
        {SyndicateStore, [],
         [
           get_syndicates: fn -> {:ok, syndicates} end,
           get_active_syndicates: fn -> {:ok, active_syndicates} end,
           get_selected_active_syndicates: fn -> {:ok, active_syndicates} end
         ]}
      ]) do
        {:ok, _view, html} = live(conn, ~p"/activate")

        assert_called(UserStore.get_user())
        assert_called(UserStore.has_user?())
        assert_called(StrategyStore.get_strategies())
        assert_called(StrategyStore.get_selected_strategy())
        assert_called(SyndicateStore.get_syndicates())
        assert_called(SyndicateStore.get_active_syndicates())
        assert_called(SyndicateStore.get_selected_active_syndicates())

        assert html =~ "Activating a syndicate will cause the app to create a sell order"
        assert html =~ "Execute Command"
      end
    end
  end

  describe "Execute button state" do
    setup_with_mocks([
      {UserStore, [], [get_user: fn -> {:ok, user} end, has_user?: fn -> true end]}
    ], %{user: user}) do
      :ok
    end

    test "it disables execute button when no strategy is selected", %{
      conn: conn,
      strategies: strategies,
      syndicates: syndicates
    } do
      selected_syndicates = Enum.filter(syndicates, fn syndicate -> syndicate.id == :steel_meridian end)

      with_mocks([
        {StrategyStore, [],
         [
           get_strategies: fn -> {:ok, strategies} end,
           get_selected_strategy: fn -> {:ok, nil} end
         ]},
        {SyndicateStore, [],
         [
           get_syndicates: fn -> {:ok, syndicates} end,
           get_active_syndicates: fn -> {:ok, []} end,
           get_selected_active_syndicates: fn -> {:ok, selected_syndicates} end
         ]}
      ]) do
        {:ok, view, _html} = live(conn, ~p"/activate")

        assert has_element?(view, "button[disabled]", "Execute Command")
      end
    end

    test "it disables execute button when no syndicates are selected", %{
      conn: conn,
      strategies: strategies,
      syndicates: syndicates
    } do
      selected_strategy = Enum.find(strategies, fn strategy -> strategy.id == :lowest_minus_one end)

      with_mocks([
        {StrategyStore, [],
         [
           get_strategies: fn -> {:ok, strategies} end,
           get_selected_strategy: fn -> {:ok, selected_strategy} end
         ]},
        {SyndicateStore, [],
         [
           get_syndicates: fn -> {:ok, syndicates} end,
           get_active_syndicates: fn -> {:ok, []} end,
           get_selected_active_syndicates: fn -> {:ok, []} end
         ]}
      ]) do
        {:ok, view, _html} = live(conn, ~p"/activate")

        assert has_element?(view, "button[disabled]", "Execute Command")
      end
    end

    test "it disables execute button when selected syndicates are already active", %{
      conn: conn,
      strategies: strategies,
      syndicates: syndicates
    } do
      selected_strategy = Enum.find(strategies, fn strategy -> strategy.id == :lowest_minus_one end)
      active_syndicates = Enum.filter(syndicates, fn syndicate -> syndicate.id == :steel_meridian end)

      with_mocks([
        {StrategyStore, [],
         [
           get_strategies: fn -> {:ok, strategies} end,
           get_selected_strategy: fn -> {:ok, selected_strategy} end
         ]},
        {SyndicateStore, [],
         [
           get_syndicates: fn -> {:ok, syndicates} end,
           get_active_syndicates: fn -> {:ok, active_syndicates} end,
           get_selected_active_syndicates: fn -> {:ok, active_syndicates} end
         ]}
      ]) do
        {:ok, view, _html} = live(conn, ~p"/activate")

        assert has_element?(view, "button[disabled]", "Execute Command")
      end
    end

    test "it enables execute button when strategy and inactive selected syndicate are present", %{
      conn: conn,
      strategies: strategies,
      syndicates: syndicates
    } do
      selected_strategy = Enum.find(strategies, fn strategy -> strategy.id == :lowest_minus_one end)
      active_syndicates = Enum.filter(syndicates, fn syndicate -> syndicate.id == :red_veil end)

      selected_syndicates =
        Enum.filter(syndicates, fn syndicate -> syndicate.id in [:red_veil, :steel_meridian] end)

      with_mocks([
        {StrategyStore, [],
         [
           get_strategies: fn -> {:ok, strategies} end,
           get_selected_strategy: fn -> {:ok, selected_strategy} end
         ]},
        {SyndicateStore, [],
         [
           get_syndicates: fn -> {:ok, syndicates} end,
           get_active_syndicates: fn -> {:ok, active_syndicates} end,
           get_selected_active_syndicates: fn -> {:ok, selected_syndicates} end
         ]}
      ]) do
        {:ok, view, _html} = live(conn, ~p"/activate")

        assert has_element?(view, "button", "Execute Command")
        refute has_element?(view, "button[disabled]", "Execute Command")
      end
    end
  end
end
