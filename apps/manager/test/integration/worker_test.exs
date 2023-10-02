defmodule Manager.WorkerTest do
  @moduledoc false

  use ExUnit.Case

  import Mock

  alias Helpers
  alias Manager.Runtime.Worker
  alias Shared.Data.{Authorization, Credentials, OrderInfo, Strategy, Syndicate, User}

  @timeout 500

  describe "activate" do
    setup do
      syndicate = Syndicate.new(name: "Red Veil", id: :red_veil)
      strategy = Strategy.new(
        name: "Top 5 Average",
        id: :top_five_average,
        description: "Gets the 5 lowest prices for the given item and calculates the average."
      )
      product1_name = "Gleaming Blight"
      product2_name = "Eroding Blight"
      invalid_id = "some_invalid_id"

      id1 = "54a74454e779892d5e5155d5"
      id2 = "54a74454e779892d5e5155a0"

      product1 = Helpers.create_product(name: product1_name, id: id1, rank: 0)
      product2 = Helpers.create_product(name: product2_name, id: id2)
      invalid_product = Helpers.create_product(name: product2_name, id: invalid_id)

      order1 = Helpers.create_order(item_id: id1, platinum: 52, mod_rank: 0)
      order2 = Helpers.create_order(item_id: id2, platinum: 50)
      invalid_order = Helpers.create_order(item_id: invalid_id, platinum: 50)

      placed_order1 = Helpers.create_placed_order(item_id: product1.id)
      placed_order2 = Helpers.create_placed_order(item_id: product2.id)
      bad_placed_order = Helpers.create_placed_order(item_id: invalid_id)

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
        product1_name: product1_name,
        product2_name: product2_name,
        invalid_product: invalid_product,
        product1: product1,
        product2: product2,
        order1: order1,
        order2: order2,
        invalid_order: invalid_order,
        placed_order1: placed_order1,
        placed_order2: placed_order2,
        bad_placed_order: bad_placed_order,
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
      placed_order1: placed_order1,
      placed_order2: placed_order2,
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
            list_orders: fn _syndicate -> {:ok, []} end,
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
            place_order: fn
              ^order1 -> {:ok, placed_order1}
              ^order2 -> {:ok, placed_order2}
            end
          ]
        }
      ]) do
        # If the process is not started, start it now
        start_supervised(Worker)

        Worker.activate(syndicate, strategy)

        assert_receive(
          {:activate, ^syndicate, {1, 2, {:ok, ^placed_order1}}},
          @timeout
        )

        assert_receive(
          {:activate, ^syndicate, {2, 2, {:ok, ^placed_order2}}},
          @timeout
        )

        assert_receive({:activate, ^syndicate, :done}, @timeout)

        assert_called(Store.list_products(syndicate))
        assert_called(Store.save_order(placed_order1, syndicate))
        assert_called(Store.save_order(placed_order2, syndicate))

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
      placed_order1 = Helpers.create_placed_order(item_id: "54a74454e779892d5e5155d5")
      placed_order2 = Helpers.create_placed_order(item_id: "54a74454e779892d5e5155a0")

      %{
        syndicate: syndicate,
        placed_order1: placed_order1,
        placed_order2: placed_order2
      }
    end

    test "deactivate works correctly", %{
      syndicate: syndicate,
      placed_order1: placed_order1,
      placed_order2: placed_order2
    } do
      with_mocks([
        {
          Store,
          [],
          [
            list_orders: fn _syndicate -> {:ok, [placed_order1, placed_order2]} end,
            delete_order: fn _placed_order, _syndicate -> :ok end
          ]
        },
        {
          AuctionHouse,
          [],
          [
            delete_order: fn _placed_order -> :ok end
          ]
        }
      ]) do
        # If the process is not started, start it now
        start_supervised(Worker)

        Worker.deactivate(syndicate)

        assert_receive(
          {:deactivate, ^syndicate, {1, 2, {:ok, ^placed_order1}}},
          @timeout
        )

        assert_receive(
          {:deactivate, ^syndicate, {2, 2, {:ok, ^placed_order2}}},
          @timeout
        )

        assert_receive({:deactivate, ^syndicate, :done}, @timeout)

        assert_called(Store.list_orders(syndicate))
        assert_called(Store.delete_order(placed_order1, syndicate))
        assert_called(Store.delete_order(placed_order2, syndicate))

        assert_called(AuctionHouse.delete_order(placed_order1))
        assert_called(AuctionHouse.delete_order(placed_order2))
      end
    end
  end

  describe "login" do
    setup do
      credentials = Credentials.new("an_email", "a_password")
      authorization = Authorization.new(%{"cookie" => "a_cookie", "token" => "a_token"})
      user = User.new(%{"ingame_name" => "fl4m3", "patreon?" => false})

      %{
        credentials: credentials,
        authorization: authorization,
        user: user
      }
    end

    test "manual login with 'keep_logged_in == false' works", %{
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

        assert_receive({:login, ^user, :done}, @timeout)

        assert_called(Store.delete_login_data())

        assert_called(AuctionHouse.login(credentials))
      end
    end

    test "manual login with 'keep_logged_in == true' works", %{
      credentials: credentials,
      authorization: authorization,
      user: user
    } do
      with_mocks([
        {
          Store,
          [],
          [
            save_login_data: fn _auth, _user -> :ok end
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

        :ok = Worker.login(credentials, true)

        assert_receive({:login, ^user, :done}, @timeout)

        assert_called(Store.save_login_data(authorization, user))

        assert_called(AuctionHouse.login(credentials))
      end
    end

  end

  # describe "recover_login" do
  #   setup do
  #     credentials = Credentials.new("an_email", "a_password")
  #     authorization = Authorization.new(%{"cookie" => "a_cookie", "token" => "a_token"})
  #     user = User.new(%{"ingame_name" => "fl4m3", "patreon?" => false})

  #     %{
  #       credentials: credentials,
  #       authorization: authorization,
  #       user: user
  #     }
  #   end

  #   # Login the user and delete authorization info in storage
  #   test "automatic login works", %{
  #     credentials: credentials,
  #     authorization: authorization,
  #     user: user
  #   } do
  #     with_mocks([
  #       {
  #         Store,
  #         [],
  #         [
  #           get_login_data: fn -> {:ok, {authorization, user}} end
  #         ]
  #       },
  #       {
  #         AuctionHouse,
  #         [],
  #         [
  #           recover_login: fn _auth, _user -> :ok end
  #         ]
  #       }
  #     ]) do
  #       # If the process is not started, start it now
  #       start_supervised(Worker)

  #       :ok = Worker.login(credentials, true)

  #       assert_receive({:login, ^credentials, :done}, @timeout)

  #       assert_called(Store.get_login_data())

  #       assert_called(AuctionHouse.recover_login(authorization, user))
  #     end
  #   end

  # end

  describe "syndicates" do
    setup do
      %{
        syndicates: [
          Syndicate.new(name: "Red Veil", id: :red_veil),
          Syndicate.new(name: "New Loka", id: :new_loka)
        ]
      }
    end

    test "returns known syndicates", %{syndicates: syndicates} do
      with_mocks([
        {
          Store,
          [],
          [
            list_syndicates: fn -> {:ok, syndicates} end
          ]
        }
      ]) do
        # If the process is not started, start it now
        start_supervised(Worker)

        assert Worker.syndicates() == {:ok, syndicates}
        assert_called(Store.list_syndicates())
      end
    end
  end

  describe "strategies" do
    test "returns the strategies" do
      # Arrange
      # If the process is not started, start it now
      start_supervised(Worker)
      expected_strategies = [
        %Strategy{
          description: "Gets the 3 lowest prices for the given item and calculates the average.",
          id: :top_three_average,
          name: "Top 3 Average"
        },
        %Strategy{
          description: "Gets the 5 lowest prices for the given item and calculates the average.",
          id: :top_five_average,
          name: "Top 5 Average"
        },
        %Strategy{
          description: "Gets the lowest price for the given item and beats it by 1.",
          id: :lowest_minus_one,
          name: "Lowest minus one"
        },
        %Strategy{
          description: "Gets the lowest price for the given item and uses it.",
          id: :equal_to_lowest,
          name: "Equal to lowest"
        }
      ]

      # Act and Assert
      assert Worker.strategies() == {:ok, expected_strategies}
    end
  end
end
