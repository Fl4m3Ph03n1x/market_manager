defmodule WebInterface.LoginLiveTest do
  @moduledoc false

  use WebInterface.ConnCase, async: false

  import Phoenix.LiveViewTest
  import Mock

  alias Shared.Data.{Credentials, User}
  alias WebInterface.Persistence.User, as: UserStore
  alias Manager

  describe "frontend events" do
    test "it submits login without remember-me and calls Manager.login/2 with false", %{conn: conn} do
      with_mocks([
        {UserStore, [], [has_user?: fn -> false end]},
        {Manager, [], [login: fn _login_credentials, _remember_me -> :ok end]}
      ]) do
        credentials = Credentials.new("fl4m3@example.com", "hunter2")

        {:ok, view, _html} = live(conn, ~p"/login")

        html =
          view
          |> form("#login_form", %{"email" => credentials.email, "password" => credentials.password})
          |> render_submit()

        assert_called(UserStore.has_user?())
        assert_called(Manager.login(credentials, false))
        assert html =~ "Logging in..."
      end
    end

    test "it submits login with remember-me and calls Manager.login/2 with true", %{conn: conn} do
      with_mocks([
        {UserStore, [], [has_user?: fn -> false end]},
        {Manager, [],
         [
           login: fn _login_credentials, _remember_me ->
             :ok
           end
         ]}
      ]) do
        credentials = Credentials.new("fl4m3@example.com", "hunter2")

        {:ok, view, _html} = live(conn, ~p"/login")

        html =
          view
          |> form("#login_form", %{
            "email" => credentials.email,
            "password" => credentials.password,
            "remember-me" => ""
          })
          |> render_submit()

        assert_called(UserStore.has_user?())
        assert_called(Manager.login(credentials, true))
        assert html =~ "Logging in..."
      end
    end
  end

  describe "backend events" do
    test "it renders the login form", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/login")

      assert html =~ "Sign into your warframe.market account"
      assert html =~ "Email address"
      assert html =~ "Password"
    end

    test "it stores the user and redirects after a successful login", %{conn: conn} do
      with_mock UserStore,
        set_user: fn _user -> :ok end,
        has_user?: fn -> false end do
        {:ok, view, _html} = live(conn, ~p"/login")

        user = User.new(ingame_name: "Fl4m3", slug: "fl4m3", patreon?: false)

        send(view.pid, {:login, {:ok, user}})

        assert_called(UserStore.set_user(user))
        assert_redirect(view, ~p"/activate")
      end
    end

    for {error, message} <- [
          {:econnrefused, "Unable to connect to warframe.market. Please verify your internet connection."},
          {:wrong_password, "Incorrect Password!"},
          {:wrong_email, "Your email is incorrect or does not exist!"},
          {:invalid_email, "Please provide a valid email!"},
          {:timeout, "The request timed out, try again later!"},
          {:unknown_error, "An unknown error occurred, please report it!"}
        ] do
      test "it shows the expected flash for #{error}", %{conn: conn} do
        {:ok, view, _html} = live(conn, ~p"/login")

        send(view.pid, {:login, {:error, unquote(error)}})

        assert render(view) =~ unquote(message)
      end
    end

    @tag capture_log: true
    test "it shows the fallback flash for an unhandled login error", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/login")

      send(view.pid, {:login, {:error, :request_failed}})

      assert render(view) =~ "Unknown message received, please check the logs and report it!"
    end
  end
end
