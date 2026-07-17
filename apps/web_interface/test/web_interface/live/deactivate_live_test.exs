defmodule WebInterface.DeactivateLiveTest do
  @moduledoc false

  use WebInterface.ConnCase, async: false

  import ExUnit.CaptureLog
  import Phoenix.LiveViewTest
  import Mock

  alias Manager
  alias Shared.Data.{Syndicate, User}
  alias WebInterface.Persistence.Syndicate, as: SyndicateStore
  alias WebInterface.Persistence.User, as: UserStore

  setup do
    user = User.new(ingame_name: "Fl4m3", slug: "fl4m3", patreon?: false)

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

    %{user: user, syndicates: syndicates}
  end

  describe "frontend events" do
    setup_with_mocks(
      [
        {UserStore, [], [get_user: fn -> {:ok, user} end, has_user?: fn -> true end]}
      ],
      %{user: user}
    ) do
      :ok
    end

    test "it executes deactivate command when button is pressed", %{
      conn: conn,
      syndicates: syndicates
    } do
      selected_syndicates = Enum.filter(syndicates, &(&1.id == :red_veil))
      inactive_syndicates = Enum.filter(syndicates, &(&1.id == :steel_meridian))

      with_mocks([
        {SyndicateStore, [],
         [
           get_syndicates: fn -> {:ok, syndicates} end,
           get_inactive_syndicates: fn -> {:ok, inactive_syndicates} end,
           get_selected_inactive_syndicates: fn -> {:ok, selected_syndicates} end,
           get_all_syndicates_by_id: fn ["red_veil"] -> {:ok, selected_syndicates} end
         ]},
        {Manager, [], [deactivate: fn [:red_veil] -> :ok end]}
      ]) do
        {:ok, view, _html} = live(conn, ~p"/deactivate")

        view
        |> form("form", %{"syndicates" => ["red_veil"]})
        |> render_submit()

        assert_called_exactly(SyndicateStore.get_all_syndicates_by_id(["red_veil"]), 1)
        assert_called_exactly(Manager.deactivate([:red_veil]), 1)
        refute has_element?(view, "form")
      end
    end

    test "it shows an error if deactivation fails", %{
      conn: conn,
      syndicates: syndicates
    } do
      selected_syndicates = Enum.filter(syndicates, &(&1.id == :red_veil))
      inactive_syndicates = Enum.filter(syndicates, &(&1.id == :steel_meridian))

      with_mocks([
        {SyndicateStore, [],
         [
           get_syndicates: fn -> {:ok, syndicates} end,
           get_inactive_syndicates: fn -> {:ok, inactive_syndicates} end,
           get_selected_inactive_syndicates: fn -> {:ok, selected_syndicates} end,
           get_all_syndicates_by_id: fn _ids -> {:error, :not_found} end
         ]},
        {Manager, [], [deactivate: fn _ids -> :ok end]}
      ]) do
        {:ok, view, _html} = live(conn, ~p"/deactivate")

        log =
          capture_log(fn ->
            view
            |> form("form", %{"syndicates" => ["red_veil"]})
            |> render_submit()
          end)

        assert_not_called(Manager.deactivate(:_))

        assert render(view) =~
                 "Unable to perform deactivation! Please check the logs for details."

        assert log =~ "Unable to perform deactivation: {:error, :not_found}"
      end
    end

    test "it changes syndicates correctly", %{
      conn: conn,
      syndicates: syndicates
    } do
      selected_syndicates = Enum.filter(syndicates, &(&1.id == :red_veil))
      inactive_syndicates = Enum.filter(syndicates, &(&1.id == :steel_meridian))
      selected_ids = ["red_veil"]
      expected_selected_syndicates = selected_syndicates ++ inactive_syndicates

      with_mocks([
        {SyndicateStore, [],
         [
           get_syndicates: fn -> {:ok, syndicates} end,
           get_inactive_syndicates: fn -> {:ok, inactive_syndicates} end,
           get_selected_inactive_syndicates: fn -> {:ok, selected_syndicates} end,
           get_all_syndicates_by_id: fn ^selected_ids -> {:ok, selected_syndicates} end,
           set_selected_inactive_syndicates: fn ^expected_selected_syndicates -> :ok end
         ]}
      ]) do
        {:ok, view, _html} = live(conn, ~p"/deactivate")

        view
        |> form("form", %{"syndicates" => selected_ids})
        |> render_change()

        assert_called_exactly(SyndicateStore.get_all_syndicates_by_id(selected_ids), 1)

        assert_called_exactly(
          SyndicateStore.set_selected_inactive_syndicates(expected_selected_syndicates),
          1
        )

        assert has_element?(view, "input#red_veil[checked]")
        assert has_element?(view, "input#steel_meridian[checked][disabled]")
      end
    end

    test "it restores inactive syndicates when no syndicates are selected", %{
      conn: conn,
      syndicates: syndicates
    } do
      selected_syndicates = Enum.filter(syndicates, &(&1.id == :red_veil))
      inactive_syndicates = Enum.filter(syndicates, &(&1.id == :steel_meridian))

      with_mocks([
        {SyndicateStore, [],
         [
           get_syndicates: fn -> {:ok, syndicates} end,
           get_inactive_syndicates: fn -> {:ok, inactive_syndicates} end,
           get_selected_inactive_syndicates: fn -> {:ok, selected_syndicates} end,
           set_selected_inactive_syndicates: fn ^inactive_syndicates -> :ok end
         ]}
      ]) do
        {:ok, view, _html} = live(conn, ~p"/deactivate")

        render_change(view, "change", %{})

        assert_called(SyndicateStore.get_inactive_syndicates())

        assert_called_exactly(
          SyndicateStore.set_selected_inactive_syndicates(inactive_syndicates),
          1
        )

        assert has_element?(view, "input#steel_meridian[checked][disabled]")
      end
    end

    test "it shows an error if changing syndicates fails", %{
      conn: conn,
      syndicates: syndicates
    } do
      selected_syndicates = Enum.filter(syndicates, &(&1.id == :red_veil))
      inactive_syndicates = Enum.filter(syndicates, &(&1.id == :steel_meridian))

      with_mocks([
        {SyndicateStore, [],
         [
           get_syndicates: fn -> {:ok, syndicates} end,
           get_inactive_syndicates: fn -> {:ok, inactive_syndicates} end,
           get_selected_inactive_syndicates: fn -> {:ok, selected_syndicates} end,
           get_all_syndicates_by_id: fn _ids -> {:error, :not_found} end,
           set_selected_inactive_syndicates: fn _syndicates -> :ok end
         ]}
      ]) do
        {:ok, view, _html} = live(conn, ~p"/deactivate")

        log =
          capture_log(fn ->
            view
            |> form("form", %{"syndicates" => ["red_veil"]})
            |> render_change()
          end)

        assert_called_exactly(SyndicateStore.get_all_syndicates_by_id(["red_veil"]), 1)
        assert_not_called(SyndicateStore.set_selected_inactive_syndicates(:_))
        assert render(view) =~ "Unable to update syndicates!"
        assert log =~ "Unable to update syndicates: {:error, :not_found}"
        assert has_element?(view, "input#red_veil[checked]")
      end
    end
  end

  describe "backend events" do
    test "it loads deactivation data on mount", %{
      conn: conn,
      user: user,
      syndicates: syndicates
    } do
      inactive_syndicates = Enum.filter(syndicates, &(&1.id == :steel_meridian))
      selected_syndicates = Enum.filter(syndicates, &(&1.id == :red_veil))

      with_mocks([
        {UserStore, [], [get_user: fn -> {:ok, user} end, has_user?: fn -> true end]},
        {SyndicateStore, [],
         [
           get_syndicates: fn -> {:ok, syndicates} end,
           get_inactive_syndicates: fn -> {:ok, inactive_syndicates} end,
           get_selected_inactive_syndicates: fn -> {:ok, selected_syndicates} end
         ]}
      ]) do
        {:ok, _view, html} = live(conn, ~p"/deactivate")

        assert_called(UserStore.get_user())
        assert_called(UserStore.has_user?())
        assert_called(SyndicateStore.get_syndicates())
        assert_called(SyndicateStore.get_inactive_syndicates())
        assert_called(SyndicateStore.get_selected_inactive_syndicates())
        assert html =~ "Deactivating a syndicate will cause the app to delete all of its orders"
        assert html =~ "Execute Command"
      end
    end

    test "it updates deactivation and reactivation progress while backend messages arrive", %{
      conn: conn,
      user: user,
      syndicates: syndicates
    } do
      inactive_syndicates = Enum.filter(syndicates, &(&1.id == :steel_meridian))
      selected_syndicates = Enum.filter(syndicates, &(&1.id == :red_veil))

      with_mocks([
        {UserStore, [], [get_user: fn -> {:ok, user} end, has_user?: fn -> true end]},
        {SyndicateStore, [],
         [
           get_syndicates: fn -> {:ok, syndicates} end,
           get_inactive_syndicates: fn -> {:ok, inactive_syndicates} end,
           get_selected_inactive_syndicates: fn -> {:ok, selected_syndicates} end
         ]}
      ]) do
        {:ok, view, _html} = live(conn, ~p"/deactivate")

        send(view.pid, {:deactivate, {:ok, :get_user_orders}})
        assert has_element?(view, "p", "Deactivate: Getting user orders.")

        send(view.pid, {:deactivate, {:ok, :deleting_orders}})
        assert has_element?(view, "p", "Deactivate: Deleting orders.")

        send(view.pid, {:deactivate, {:ok, {:order_deleted, "Rift Haven", 3, 4}}})
        assert has_element?(view, "span", "75")

        send(view.pid, {:deactivate, {:ok, :reactivating_remaining_syndicates}})
        assert has_element?(view, "p", "Deactivate: Action completed, recalculating remaining syndicates.")

        send(view.pid, {:activate, {:ok, :get_user_orders}})
        assert has_element?(view, "p", "Deactivate: Getting remaining user orders.")

        send(view.pid, {:activate, {:ok, :calculating_item_prices}})
        assert has_element?(view, "p", "Deactivate: Recalculating item prices.")

        send(view.pid, {:activate, {:ok, {:price_calculated, "Rift Haven", 42, 1, 4}}})
        assert has_element?(view, "span", "25")

        send(view.pid, {:activate, {:ok, :placing_orders}})
        assert has_element?(view, "p", "Deactivate: Placing updated orders.")

        send(view.pid, {:activate, {:ok, {:order_placed, "Rift Haven", 3, 4}}})
        assert has_element?(view, "span", "75")
      end
    end

    test "it persists deactivated syndicates and returns to the form when deactivation completes", %{
      conn: conn,
      user: user,
      syndicates: syndicates
    } do
      inactive_syndicates = Enum.filter(syndicates, &(&1.id in [:red_veil, :steel_meridian]))
      selected_syndicates = Enum.filter(syndicates, &(&1.id == :red_veil))
      expected_selected_syndicates = Enum.uniq(selected_syndicates ++ inactive_syndicates)

      with_mocks([
        {UserStore, [], [get_user: fn -> {:ok, user} end, has_user?: fn -> true end]},
        {SyndicateStore, [],
         [
           get_syndicates: fn -> {:ok, syndicates} end,
           get_inactive_syndicates: fn -> {:ok, inactive_syndicates} end,
           get_selected_inactive_syndicates: fn -> {:ok, selected_syndicates} end,
           deactivate_syndicates: fn ^selected_syndicates -> :ok end,
           set_selected_inactive_syndicates: fn ^expected_selected_syndicates -> :ok end
         ]}
      ]) do
        {:ok, view, _html} = live(conn, ~p"/deactivate")

        send(view.pid, {:deactivate, {:ok, :done}})

        assert has_element?(view, "button", "Execute Command")
        assert has_element?(view, "input#red_veil[checked]")
        refute has_element?(view, "p", "Deactivate: Deleting orders.")
        assert_called(SyndicateStore.deactivate_syndicates(selected_syndicates))
        assert_called(SyndicateStore.set_selected_inactive_syndicates(expected_selected_syndicates))
      end
    end

    test "it persists deactivated syndicates when reactivation completes", %{
      conn: conn,
      user: user,
      syndicates: syndicates
    } do
      inactive_syndicates = Enum.filter(syndicates, &(&1.id in [:red_veil, :steel_meridian]))
      selected_syndicates = Enum.filter(syndicates, &(&1.id == :red_veil))
      expected_selected_syndicates = Enum.uniq(selected_syndicates ++ inactive_syndicates)

      with_mocks([
        {UserStore, [], [get_user: fn -> {:ok, user} end, has_user?: fn -> true end]},
        {SyndicateStore, [],
         [
           get_syndicates: fn -> {:ok, syndicates} end,
           get_inactive_syndicates: fn -> {:ok, inactive_syndicates} end,
           get_selected_inactive_syndicates: fn -> {:ok, selected_syndicates} end,
           deactivate_syndicates: fn ^selected_syndicates -> :ok end,
           set_selected_inactive_syndicates: fn ^expected_selected_syndicates -> :ok end
         ]}
      ]) do
        {:ok, view, _html} = live(conn, ~p"/deactivate")

        send(view.pid, {:activate, {:ok, :done}})

        assert has_element?(view, "button", "Execute Command")
        assert_called(SyndicateStore.deactivate_syndicates(selected_syndicates))
        assert_called(SyndicateStore.set_selected_inactive_syndicates(expected_selected_syndicates))
      end
    end

    @tag :capture_log
    test "it shows an error when deactivation completion fails", %{
      conn: conn,
      user: user,
      syndicates: syndicates
    } do
      inactive_syndicates = Enum.filter(syndicates, &(&1.id == :steel_meridian))
      selected_syndicates = Enum.filter(syndicates, &(&1.id == :red_veil))

      with_mocks([
        {UserStore, [], [get_user: fn -> {:ok, user} end, has_user?: fn -> true end]},
        {SyndicateStore, [],
         [
           get_syndicates: fn -> {:ok, syndicates} end,
           get_inactive_syndicates: fn -> {:ok, inactive_syndicates} end,
           get_selected_inactive_syndicates: fn -> {:ok, selected_syndicates} end,
           deactivate_syndicates: fn ^selected_syndicates -> {:error, :not_found} end,
           set_selected_inactive_syndicates: fn _syndicates -> :ok end
         ]}
      ]) do
        {:ok, view, _html} = live(conn, ~p"/deactivate")

        send(view.pid, {:deactivate, {:ok, :done}})

        assert render(view) =~ "Unable to complete syndicate deactivation!"
      end
    end

    @tag :capture_log
    test "it resets the view and shows a flash when reactivation fails", %{
      conn: conn,
      user: user,
      syndicates: syndicates
    } do
      inactive_syndicates = Enum.filter(syndicates, &(&1.id == :steel_meridian))
      selected_syndicates = Enum.filter(syndicates, &(&1.id == :red_veil))

      with_mocks([
        {UserStore, [], [get_user: fn -> {:ok, user} end, has_user?: fn -> true end]},
        {SyndicateStore, [],
         [
           get_syndicates: fn -> {:ok, syndicates} end,
           get_inactive_syndicates: fn -> {:ok, inactive_syndicates} end,
           get_selected_inactive_syndicates: fn -> {:ok, selected_syndicates} end
         ]}
      ]) do
        {:ok, view, _html} = live(conn, ~p"/deactivate")

        send(view.pid, {:activate, {:error, :timeout}})

        assert has_element?(view, "form")

        assert render(view) =~
                 "The selected syndicates were deactivated, but reactivation of the remaining ones failed."

        refute has_element?(view, "p", "Deactivate: Recalculating item prices.")
      end
    end

    @tag :capture_log
    test "it shows a fallback flash for an unknown backend message", %{
      conn: conn,
      user: user,
      syndicates: syndicates
    } do
      inactive_syndicates = Enum.filter(syndicates, &(&1.id == :steel_meridian))
      selected_syndicates = Enum.filter(syndicates, &(&1.id == :red_veil))

      with_mocks([
        {UserStore, [], [get_user: fn -> {:ok, user} end, has_user?: fn -> true end]},
        {SyndicateStore, [],
         [
           get_syndicates: fn -> {:ok, syndicates} end,
           get_inactive_syndicates: fn -> {:ok, inactive_syndicates} end,
           get_selected_inactive_syndicates: fn -> {:ok, selected_syndicates} end
         ]}
      ]) do
        {:ok, view, _html} = live(conn, ~p"/deactivate")

        send(view.pid, {:unexpected, :message})

        assert render(view) =~ "Something unexpected happened, please report it!"
      end
    end
  end

  describe "Execute button state" do
    setup_with_mocks(
      [
        {UserStore, [], [get_user: fn -> {:ok, user} end, has_user?: fn -> true end]}
      ],
      %{user: user}
    ) do
      :ok
    end

    test "it disables execute button when no syndicates are selected", %{
      conn: conn,
      syndicates: syndicates
    } do
      inactive_syndicates = Enum.filter(syndicates, &(&1.id == :steel_meridian))

      with_mocks([
        {SyndicateStore, [],
         [
           get_syndicates: fn -> {:ok, syndicates} end,
           get_inactive_syndicates: fn -> {:ok, inactive_syndicates} end,
           get_selected_inactive_syndicates: fn -> {:ok, []} end
         ]}
      ]) do
        {:ok, view, _html} = live(conn, ~p"/deactivate")

        assert has_element?(view, "button[disabled]", "Execute Command")
      end
    end

    test "it disables execute button when selected syndicates are already inactive", %{
      conn: conn,
      syndicates: syndicates
    } do
      inactive_syndicates = Enum.filter(syndicates, &(&1.id == :steel_meridian))

      with_mocks([
        {SyndicateStore, [],
         [
           get_syndicates: fn -> {:ok, syndicates} end,
           get_inactive_syndicates: fn -> {:ok, inactive_syndicates} end,
           get_selected_inactive_syndicates: fn -> {:ok, inactive_syndicates} end
         ]}
      ]) do
        {:ok, view, _html} = live(conn, ~p"/deactivate")

        assert has_element?(view, "button[disabled]", "Execute Command")
      end
    end

    test "it enables execute button when selected active syndicates are present", %{
      conn: conn,
      syndicates: syndicates
    } do
      inactive_syndicates = Enum.filter(syndicates, &(&1.id == :steel_meridian))
      selected_syndicates = Enum.filter(syndicates, &(&1.id == :red_veil))

      with_mocks([
        {SyndicateStore, [],
         [
           get_syndicates: fn -> {:ok, syndicates} end,
           get_inactive_syndicates: fn -> {:ok, inactive_syndicates} end,
           get_selected_inactive_syndicates: fn -> {:ok, selected_syndicates} end
         ]}
      ]) do
        {:ok, view, _html} = live(conn, ~p"/deactivate")

        assert has_element?(view, "button", "Execute Command")
        refute has_element?(view, "button[disabled]", "Execute Command")
      end
    end
  end
end
