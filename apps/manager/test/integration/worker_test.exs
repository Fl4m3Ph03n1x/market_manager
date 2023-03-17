defmodule Manager.WorkerTest do
  @moduledoc false

  use ExUnit.Case

  import Mock

  alias Helpers
  alias Manager.Runtime.Worker
  alias Shared.Data.{Authorization, Credentials, OrderInfo, User}

  @timeout 500

  describe "activate" do
    setup do
      syndicate = "red_veil"
      strategy = :top_five_average
      id1 = "54a74454e779892d5e5155d5"
      id2 = "54a74454e779892d5e5155a0"
      product1_name = "Gleaming Blight"
      product2_name = "Eroding Blight"
      invalid_id = "some_invalid_id"

      product1 = Helpers.create_product(name: product1_name, id: id1, rank: 0)
      product2 = Helpers.create_product(name: product2_name, id: id2)
      invalid_product = Helpers.create_product(name: product2_name, id: invalid_id)

      order1 = Helpers.create_order(item_id: id1, platinum: 52, mod_rank: 0)
      order2 = Helpers.create_order(item_id: id2, platinum: 50)
      invalid_order = Helpers.create_order(item_id: invalid_id, platinum: 50)

      order1_without_market_info = Helpers.create_order(item_id: id1, platinum: 16, mod_rank: 0)
      order2_without_market_info = Helpers.create_order(item_id: id2, platinum: 16)

      product1_market_orders = [
        OrderInfo.new(%{
          "order_type" => "sell",
          "platinum" => 45,
          "platform" => "pc",
          "user" => %{
            "status" => "ingame",
            "ingame_name" => "ingame_name_1"
          },
          "visible" => true
        }),
        OrderInfo.new(%{
          "order_type" => "sell",
          "platinum" => 55,
          "platform" => "pc",
          "user" => %{
            "status" => "ingame",
            "ingame_name" => "ingame_name_2"
          },
          "visible" => true
        }),
        OrderInfo.new(%{
          "order_type" => "sell",
          "platinum" => 50,
          "platform" => "pc",
          "user" => %{
            "status" => "ingame",
            "ingame_name" => "ingame_name_3"
          },
          "visible" => true
        }),
        OrderInfo.new(%{
          "order_type" => "sell",
          "platinum" => 60,
          "platform" => "pc",
          "user" => %{
            "status" => "ingame",
            "ingame_name" => "ingame_name_4"
          },
          "visible" => true
        }),
        OrderInfo.new(%{
          "order_type" => "sell",
          "platinum" => 50,
          "platform" => "pc",
          "user" => %{
            "status" => "ingame",
            "ingame_name" => "ingame_name_5"
          },
          "visible" => true
        })
      ]

      product2_market_orders = [
        OrderInfo.new(%{
          "order_type" => "sell",
          "platinum" => 40,
          "platform" => "pc",
          "user" => %{
            "status" => "ingame",
            "ingame_name" => "ingame_name_6"
          },
          "visible" => true
        }),
        OrderInfo.new(%{
          "order_type" => "sell",
          "platinum" => 50,
          "platform" => "pc",
          "user" => %{
            "status" => "ingame",
            "ingame_name" => "ingame_name_7"
          },
          "visible" => true
        }),
        OrderInfo.new(%{
          "order_type" => "sell",
          "platinum" => 50,
          "platform" => "pc",
          "user" => %{
            "status" => "ingame",
            "ingame_name" => "ingame_name_8"
          },
          "visible" => true
        }),
        OrderInfo.new(%{
          "order_type" => "sell",
          "platinum" => 60,
          "platform" => "pc",
          "user" => %{
            "status" => "ingame",
            "ingame_name" => "ingame_name_9"
          },
          "visible" => true
        }),
        OrderInfo.new(%{
          "order_type" => "sell",
          "platinum" => 50,
          "platform" => "pc",
          "user" => %{
            "status" => "ingame",
            "ingame_name" => "ingame_name_10"
          },
          "visible" => true
        })
      ]

      %{
        syndicate: syndicate,
        strategy: strategy,
        id1: id1,
        id2: id2,
        product1_name: product1_name,
        product2_name: product2_name,
        invalid_product: invalid_product,
        product1: product1,
        product2: product2,
        order1: order1,
        order2: order2,
        invalid_order: invalid_order,
        order1_without_market_info: order1_without_market_info,
        order2_without_market_info: order2_without_market_info,
        product1_market_orders: product1_market_orders,
        product2_market_orders: product2_market_orders
      }
    end

    test "Receives progress messages correctly", %{
      syndicate: syndicate,
      strategy: strategy,
      product1: product1,
      product2: product2,
      product1_name: product1_name,
      product2_name: product2_name,
      id1: id1,
      id2: id2,
      order1: order1,
      order2: order2,
      product1_market_orders: product1_market_orders,
      product2_market_orders: product2_market_orders
    } do
      with_mocks([
        {
          Store,
          [],
          [
            list_products: fn _syndicate -> {:ok, [product1, product2]} end,
            save_order: fn _id, _syndicate -> :ok end
          ]
        },
        {
          AuctionHouse,
          [],
          [
            get_all_orders: fn
              ^product1_name -> {:ok, product1_market_orders}
              ^product2_name -> {:ok, product2_market_orders}
            end,
            place_order: fn order -> {:ok, order.item_id} end
          ]
        }
      ]) do
        # If the process is not started, start it now
        start_supervised(Worker)

        Worker.activate(syndicate, strategy)

        assert_receive(
          {:activate, ^syndicate, {1, 2, {:ok, "54a74454e779892d5e5155d5"}}},
          @timeout
        )

        assert_receive(
          {:activate, ^syndicate, {2, 2, {:ok, "54a74454e779892d5e5155a0"}}},
          @timeout
        )

        assert_receive({:activate, ^syndicate, :done}, @timeout)

        assert_called(Store.list_products(syndicate))
        assert_called(Store.save_order(id1, syndicate))
        assert_called(Store.save_order(id2, syndicate))

        assert_called(AuctionHouse.get_all_orders(product1_name))
        assert_called(AuctionHouse.get_all_orders(product2_name))
        assert_called(AuctionHouse.place_order(order1))
        assert_called(AuctionHouse.place_order(order2))
      end
    end
  end

  describe "deactivate" do
    setup do
      syndicate = "red_veil"
      order_id1 = "54a74454e779892d5e5155d5"
      order_id2 = "54a74454e779892d5e5155a0"

      %{
        syndicate: syndicate,
        order_id1: order_id1,
        order_id2: order_id2
      }
    end

    test "deactivate works correctly", %{
      syndicate: syndicate,
      order_id1: order_id1,
      order_id2: order_id2
    } do
      with_mocks([
        {
          Store,
          [],
          [
            list_orders: fn _syndicate -> {:ok, [order_id1, order_id2]} end,
            delete_order: fn id, _syndicate -> {:ok, id} end
          ]
        },
        {
          AuctionHouse,
          [],
          [
            delete_order: fn order_id -> {:ok, order_id} end
          ]
        }
      ]) do
        # If the process is not started, start it now
        start_supervised(Worker)

        Worker.deactivate(syndicate)

        assert_receive(
          {:deactivate, ^syndicate, {1, 2, {:ok, "54a74454e779892d5e5155d5"}}},
          @timeout
        )

        assert_receive(
          {:deactivate, ^syndicate, {2, 2, {:ok, "54a74454e779892d5e5155a0"}}},
          @timeout
        )

        assert_receive({:deactivate, ^syndicate, :done}, @timeout)

        assert_called(Store.list_orders(syndicate))
        assert_called(Store.delete_order(order_id1, syndicate))
        assert_called(Store.delete_order(order_id2, syndicate))

        assert_called(AuctionHouse.delete_order(order_id1))
        assert_called(AuctionHouse.delete_order(order_id2))
      end
    end
  end

  describe "login" do
    setup do
      credentials = Credentials.new("an_email", "a_password")
      authorization = Authorization.new("a_cookie", "a_token")
      user = User.new("fl4m3", false)

      %{
        credentials: credentials,
        authorization: authorization,
        user: user
      }
    end

    # Login the user and delete authorization info in storage
    test "automatic login works", %{
      credentials: credentials,
      authorization: authorization,
      user: user
    } do
      with_mocks([
        {
          Store,
          [],
          [
            get_login_data: fn -> {:ok, {authorization, user}} end
          ]
        },
        {
          AuctionHouse,
          [],
          [
            recover_login: fn _auth, _user -> :ok end
          ]
        }
      ]) do
        # If the process is not started, start it now
        start_supervised(Worker)

        :ok = Worker.login(credentials, true)

        assert_receive({:login, ^credentials, :done}, @timeout)

        assert_called(Store.get_login_data())

        assert_called(AuctionHouse.recover_login(authorization, user))
      end
    end

    # Login the user and update/save authorization information in storage
    test "manual login works", %{
      credentials: credentials,
      authorization: authorization,
      user: user
    } do
      with_mocks([
        {
          Store,
          [],
          [
            delete_login_data: fn -> :ok end
          ]
        },
        {
          AuctionHouse,
          [],
          [
            login: fn _credentials -> {:ok, {authorization, user}} end
          ]
        }
      ]) do
        # If the process is not started, start it now
        start_supervised(Worker)

        :ok = Worker.login(credentials, false)

        assert_receive({:login, ^credentials, :done}, @timeout)

        assert_called(Store.delete_login_data())

        assert_called(AuctionHouse.login(credentials))
      end
    end
  end
end
