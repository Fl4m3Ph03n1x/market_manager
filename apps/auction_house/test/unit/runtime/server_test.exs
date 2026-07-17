defmodule AuctionHouse.Runtime.ServerTest do
  @moduledoc false

  use ExUnit.Case

  import ExUnit.CaptureLog
  import Mock

  alias AuctionHouse.Impl.UseCase.{DeleteOrder, GetItemOrders, GetUserOrders, Login, PlaceOrder}
  alias AuctionHouse.Runtime.Server
  alias Shared.Data.{Authorization, Credentials, PlacedOrder, User}

  describe "init/1" do
    test "starts with no saved login" do
      parent = self()

      spawn(fn -> send(parent, {:initialized, Server.init(nil)}) end)

      assert_receive {:initialized, {:ok, %{authorization: nil, user: nil}}}
    end
  end

  describe "child_spec/1" do
    test "uses the server as the child id and start module" do
      assert Server.child_spec([]) == %{id: Server, start: {Server, :start_link, []}}
    end
  end

  describe "handle_cast/2" do
    test "starts a place order request with the current authorization" do
      order = %{itemId: "item_id", platinum: 10, quantity: 1}
      authorization = %Authorization{cookie: "a_cookie", token: "a_token"}
      state = %{authorization: authorization, user: nil}
      from = self()

      with_mocks([
        {
          PlaceOrder,
          [],
          [
            start: fn request ->
              assert request.metadata.operation == :place_order
              assert request.metadata.notify == [from]
              assert request.args == %{order: order, authorization: authorization}
              :ok
            end
          ]
        }
      ]) do
        assert Server.handle_cast({:place_order, order, from}, state) == {:noreply, state}
      end
    end

    test "starts a delete order request with the current authorization" do
      placed_order = %PlacedOrder{item_id: "item_id", order_id: "order_id"}
      authorization = %Authorization{cookie: "a_cookie", token: "a_token"}
      state = %{authorization: authorization, user: nil}
      from = self()

      with_mocks([
        {
          DeleteOrder,
          [],
          [
            start: fn request ->
              assert request.metadata.operation == :delete_order
              assert request.metadata.notify == [from]
              assert request.args == %{placed_order: placed_order, authorization: authorization}
              :ok
            end
          ]
        }
      ]) do
        assert Server.handle_cast({:delete_order, placed_order, from}, state) == {:noreply, state}
      end
    end

    test "starts an item orders request" do
      item_name = "Serration"
      state = %{authorization: nil, user: nil}
      from = self()

      with_mocks([
        {
          GetItemOrders,
          [],
          [
            start: fn request ->
              assert request.metadata.operation == :get_item_orders
              assert request.metadata.notify == [from]
              assert request.args == %{item_name: item_name}
              :ok
            end
          ]
        }
      ]) do
        assert Server.handle_cast({:get_item_orders, item_name, from}, state) == {:noreply, state}
      end
    end

    test "starts a user orders request" do
      username_slug = "fl4m3"
      state = %{authorization: nil, user: nil}
      from = self()

      with_mocks([
        {
          GetUserOrders,
          [],
          [
            start: fn request ->
              assert request.metadata.operation == :get_user_orders
              assert request.metadata.notify == [from]
              assert request.args == %{username_slug: username_slug}
              :ok
            end
          ]
        }
      ]) do
        assert Server.handle_cast({:get_user_orders, username_slug, from}, state) == {:noreply, state}
      end
    end

    test "starts a login request and notifies the server" do
      credentials = %Credentials{email: "user@example.com", password: "password"}
      state = %{authorization: nil, user: nil}
      from = self()

      with_mocks([
        {
          Login,
          [],
          [
            start: fn request ->
              assert request.metadata.operation == :login
              assert request.metadata.notify == [from, self()]
              assert request.args == %{credentials: credentials}
              :ok
            end
          ]
        }
      ]) do
        assert Server.handle_cast({:login, credentials, from}, state) == {:noreply, state}
      end
    end
  end

  describe "handle_call/3" do
    test "updates both login fields" do
      authorization = %Authorization{cookie: "a_cookie", token: "a_token"}
      user = %User{ingame_name: "Fl4m3", slug: "fl4m3", patreon?: false}
      state = %{authorization: nil, user: nil}

      assert Server.handle_call({:update_login, authorization, user}, self(), state) ==
               {:reply, :ok, %{authorization: authorization, user: user}}
    end

    test "returns the saved login without changing state" do
      authorization = %Authorization{cookie: "a_cookie", token: "a_token"}
      user = %User{ingame_name: "Fl4m3", slug: "fl4m3", patreon?: false}
      state = %{authorization: authorization, user: user}

      assert Server.handle_call({:get_saved_login}, self(), state) ==
               {:reply, {:ok, {authorization, user}}, state}
    end

    test "clears both login fields on logout" do
      state = %{
        authorization: %Authorization{cookie: "a_cookie", token: "a_token"},
        user: %User{ingame_name: "Fl4m3", slug: "fl4m3", patreon?: false}
      }

      assert Server.handle_call(:logout, self(), state) ==
               {:reply, :ok, %{authorization: nil, user: nil}}
    end
  end

  describe "handle_info/2" do
    test "ignores a normally exiting process" do
      state = %{authorization: nil, user: nil}

      assert Server.handle_info({:EXIT, self(), :normal}, state) == {:noreply, state}
    end

    test "stores authorization and user after a successful login" do
      authorization = %Authorization{cookie: "a_cookie", token: "a_token"}
      user = %User{ingame_name: "Fl4m3", slug: "fl4m3", patreon?: false}
      state = %{authorization: nil, user: nil}

      assert Server.handle_info({:login, {:ok, {authorization, user}}}, state) ==
               {:noreply, %{authorization: authorization, user: user}}
    end

    test "clears a previous login after a failed login" do
      state = %{
        authorization: %Authorization{cookie: "a_cookie", token: "a_token"},
        user: %User{ingame_name: "Fl4m3", slug: "fl4m3", patreon?: false}
      }

      assert Server.handle_info({:login, {:error, :invalid_credentials}}, state) ==
               {:noreply, %{authorization: nil, user: nil}}
    end

    test "preserves state after a successful operation" do
      state = %{authorization: nil, user: nil}

      assert Server.handle_info({:get_item_orders, {:ok, []}}, state) == {:noreply, state}
    end

    test "logs an operation error and preserves state" do
      state = %{authorization: nil, user: nil}

      log =
        capture_log(fn ->
          assert Server.handle_info({:get_item_orders, {:error, :not_found}}, state) ==
                   {:noreply, state}
        end)

      assert log =~ "Error for operation: get_item_orders"
      assert log =~ "{:error, :not_found}"
    end
  end
end
