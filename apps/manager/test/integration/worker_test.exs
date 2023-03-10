defmodule Manager.WorkerTest do
  @moduledoc false

  use ExUnit.Case

  import Mock

  alias Helpers
  alias Manager.Runtime.Worker
  alias Shared.Data.{Order, OrderInfo}

  describe "activate" do
    setup do
      syndicate = "red_veil"
      strategy = :top_five_average
      id1 = "54a74454e779892d5e5155d5"
      id2 = "54a74454e779892d5e5155a0"
      product1_name = "Gleaming Blight"
      product2_name = "Eroding Blight"
      invalid_id = "some_invalid_id"

      product1 = Helpers.create_product(product1_name, id1)
      product2 = Helpers.create_product(product2_name, id2, "n/a")
      invalid_product = Helpers.create_product(product2_name, invalid_id, "n/a")

      order1 = Helpers.create_order(id1, 52, 0)
      order2 = Helpers.create_order(id2, 50)
      invalid_order = Helpers.create_order(invalid_id, 50)

      order1_without_market_info =
        Order.new(%{
          "item_id" => "54a74454e779892d5e5155d5",
          "mod_rank" => 0,
          "order_type" => "sell",
          "platinum" => 16,
          "quantity" => 1
        })

      order2_without_market_info =
        Order.new(%{
          "item_id" => "54a74454e779892d5e5155a0",
          "order_type" => "sell",
          "platinum" => 16,
          "quantity" => 1
        })

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

        assert_receive {:activate, ^syndicate, {1, 2, {:ok, "54a74454e779892d5e5155d5"}}}
        assert_receive {:activate, ^syndicate, {2, 2, {:ok, "54a74454e779892d5e5155a0"}}}
        assert_receive {:activate, ^syndicate, :done}

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

        assert_receive {:deactivate, ^syndicate, {1, 2, {:ok, "54a74454e779892d5e5155d5"}}}
        assert_receive {:deactivate, ^syndicate, {2, 2, {:ok, "54a74454e779892d5e5155a0"}}}
        assert_receive {:deactivate, ^syndicate, :done}

        assert_called(Store.list_orders(syndicate))
        assert_called(Store.delete_order(order_id1, syndicate))
        assert_called(Store.delete_order(order_id2, syndicate))

        assert_called(AuctionHouse.delete_order(order_id1))
        assert_called(AuctionHouse.delete_order(order_id2))
      end
    end
  end
end
