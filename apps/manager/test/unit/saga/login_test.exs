defmodule Manager.Saga.LoginTest do
  @moduledoc false

  use ExUnit.Case

  import Mock

  alias AuctionHouse
  alias Manager.Saga.Login
  alias Shared.Data.{Authorization, Credentials, User}
  alias Store

  setup do
    credentials = %Credentials{email: "user@example.com", password: "password"}
    authorization = %Authorization{cookie: "a_cookie", token: "a_token"}
    user = %User{ingame_name: "Fl4m3", slug: "fl4m3", patreon?: false}

    state = %{
      deps: %{store: Store, auction_house: AuctionHouse},
      args: %{credentials: credentials, keep_logged_in: false},
      from: self()
    }

    {:ok,
     credentials: credentials,
     authorization: authorization,
     user: user,
     state: state,
     state_keep_logged_in: %{state | args: %{state.args | keep_logged_in: true}}}
  end

  describe "init/1" do
    test "continues with the given state", %{state: state} do
      assert Login.init(state) == {:ok, state, {:continue, nil}}
    end
  end

  describe "handle_continue/2" do
    test "uses saved login data and saves it again when keep_logged_in is enabled", %{
      authorization: authorization,
      user: user,
      credentials: credentials,
      state_keep_logged_in: state
    } do
      with_mocks([
        {
          Store,
          [],
          [
            get_login_data: fn -> {:ok, {authorization, user}} end,
            save_login_data: fn _authorization, _user -> :ok end
          ]
        },
        {
          AuctionHouse,
          [],
          [
            update_login: fn _authorization, _user -> :ok end
          ]
        }
      ]) do
        assert Login.handle_continue(nil, state) == {:noreply, state}
        assert_receive {:login, {:ok, ^user}}
        assert_not_called(Store.delete_login_data())
        assert_not_called(AuctionHouse.login(credentials))
        assert_called(Store.save_login_data(authorization, user))
        assert_called(AuctionHouse.update_login(authorization, user))
      end
    end

    test "uses saved login data and deletes it when keep_logged_in is disabled", %{
      authorization: authorization,
      user: user,
      credentials: credentials,
      state: state
    } do
      with_mocks([
        {
          Store,
          [],
          [
            get_login_data: fn -> {:ok, {authorization, user}} end,
            delete_login_data: fn -> :ok end
          ]
        },
        {
          AuctionHouse,
          [],
          [update_login: fn _authorization, _user -> :ok end]
        }
      ]) do
        assert Login.handle_continue(nil, state) == {:noreply, state}
        assert_receive {:login, {:ok, ^user}}
        assert_called(Store.delete_login_data())
        assert_not_called(Store.save_login_data(authorization, user))
        assert_not_called(AuctionHouse.login(credentials))
        assert_called(AuctionHouse.update_login(authorization, user))
      end
    end

    test "starts a fresh login when no saved login exists", %{
      credentials: credentials,
      state_keep_logged_in: state
    } do
      with_mocks([
        {Store, [], [get_login_data: fn -> {:ok, nil} end]},
        {AuctionHouse, [], [login: fn _credentials -> :ok end]}
      ]) do
        assert Login.handle_continue(nil, state) == {:noreply, state}
        assert_called(AuctionHouse.login(credentials))
        refute_received {:login, _}
      end
    end

    test "starts a fresh login when saved login data cannot be read", %{
      credentials: credentials,
      state: state
    } do
      with_mocks([
        {Store, [], [get_login_data: fn -> {:error, :enoent} end]},
        {AuctionHouse, [], [login: fn _credentials -> :ok end]}
      ]) do
        assert Login.handle_continue(nil, state) == {:noreply, state}
        assert_called(AuctionHouse.login(credentials))
        refute_received {:login, _}
      end
    end

    test "starts a fresh login when updating saved login data fails", %{
      credentials: credentials,
      authorization: authorization,
      user: user,
      state_keep_logged_in: state
    } do
      with_mocks([
        {Store, [], [get_login_data: fn -> {:ok, {authorization, user}} end]},
        {
          AuctionHouse,
          [],
          [
            update_login: fn _authorization, _user -> {:error, :server_down} end,
            login: fn _credentials -> :ok end
          ]
        }
      ]) do
        assert Login.handle_continue(nil, state) == {:noreply, state}
        assert_called(AuctionHouse.login(credentials))
        assert_not_called(Store.save_login_data(authorization, user))
        assert_not_called(Store.delete_login_data())
        assert_called(AuctionHouse.update_login(authorization, user))
      end
    end
  end

  describe "handle_info/2" do
    test "saves a successful login when keep_logged_in is enabled", %{
      authorization: authorization,
      user: user,
      state_keep_logged_in: state
    } do
      with_mocks([
        {Store, [], [save_login_data: fn _authorization, _user -> :ok end]}
      ]) do
        assert Login.handle_info({:login, {:ok, {authorization, user}}}, state) ==
                 {:stop, :normal, state}

        assert_receive {:login, {:ok, ^user}}
        assert_called(Store.save_login_data(authorization, user))
        assert_not_called(Store.delete_login_data())
      end
    end

    test "deletes a successful login when keep_logged_in is disabled", %{
      authorization: authorization,
      user: user,
      state: state
    } do
      with_mocks([
        {Store, [], [delete_login_data: fn -> :ok end]}
      ]) do
        assert Login.handle_info({:login, {:ok, {authorization, user}}}, state) ==
                 {:stop, :normal, state}

        assert_receive {:login, {:ok, ^user}}
        assert_called(Store.delete_login_data())
        assert_not_called(Store.save_login_data(authorization, user))
      end
    end

    test "forwards a failed login and stops normally", %{state: state} do
      error = {:error, :invalid_credentials}

      assert Login.handle_info({:login, error}, state) == {:stop, :normal, state}
      assert_receive {:login, ^error}
    end
  end
end
