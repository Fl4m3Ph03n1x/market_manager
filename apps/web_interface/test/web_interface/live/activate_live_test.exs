defmodule WebInterface.ActivateLiveTest do
  @moduledoc false

  use WebInterface.ConnCase, async: false

  import Phoenix.LiveViewTest
  import Mock

  alias Shared.Data.{Strategy, Syndicate, User}
  alias WebInterface.Persistence.Strategy, as: StrategyStore
  alias WebInterface.Persistence.Syndicate, as: SyndicateStore
  alias WebInterface.Persistence.User, as: UserStore
  alias Manager

  describe "frontend events" do
    test "it executes activate command when button is pressed", %{conn: conn} do
      user = User.new(ingame_name: "Fl4m3", slug: "fl4m3", patreon?: false)

      strategy =
        Strategy.new(
          name: "Lowest minus one",
          id: :lowest_minus_one,
          description: "Undercut the lowest visible price by one platinum."
        )

      syndicate =
        Syndicate.new(
          name: "Steel Meridian",
          id: :steel_meridian,
          catalog: []
        )

      strategy_id = Atom.to_string(strategy.id)
      syndicate_id = Atom.to_string(syndicate.id)

      with_mocks([
        {UserStore, [], [get_user: fn -> {:ok, user} end, has_user?: fn -> true end]},
        {StrategyStore, [],
         [
           get_strategies: fn -> {:ok, [strategy]} end,
           get_selected_strategy: fn -> {:ok, strategy} end,
           get_strategy_by_id: fn _id -> {:ok, strategy} end
         ]},
        {SyndicateStore, [],
         [
           get_syndicates: fn -> {:ok, [syndicate]} end,
           get_active_syndicates: fn -> {:ok, []} end,
           get_selected_active_syndicates: fn -> {:ok, [syndicate]} end,
           get_all_syndicates_by_id: fn _ids -> {:ok, [syndicate]} end
         ]},
        {Manager, [], [activate: fn _params -> :ok end]}
      ]) do
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
  end

  describe "backend events" do
  end
end
