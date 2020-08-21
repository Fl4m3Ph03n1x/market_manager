defmodule Manager.InterpreterTest do
  use ExUnit.Case

  import Hammox

  alias Manager.{AuctionHouseMock, Interpreter, StoreMock}

  # Make sure mocks are verified when the test exits
  setup :verify_on_exit!

  describe "activate/1" do
    test "Places orders in auction house and saves order ids" do
      # Arrange
      syndicate = "red_veil"
      strategy = :top_five_average
      id1 = "54a74454e779892d5e5155d5"
      id2 = "54a74454e779892d5e5155a0"
      product1_name = "Gleaming Blight"
      product2_name = "Eroding Blight"

      product1 = %{
        "name" => product1_name,
        "id" => id1,
        "price" => 15
      }
      product2 = %{
        "name" => product2_name,
        "id" => id2,
        "price" => 15,
        "rank" => "n/a"
      }

      order1 = %{
        "order_type" => "sell",
        "item_id" => id1,
        "platinum" => 52,
        "quantity" => 1,
        "mod_rank" => 0
      }

      order2 = %{
        "order_type" => "sell",
        "item_id" => id2,
        "platinum" => 50,
        "quantity" => 1
      }

      product1_market_orders = [
        %{
          "order_type" => "sell",
          "platinum" => 45,
          "platform" => "pc",
          "user" => %{
            "status" => "ingame"
          },
          "visible" => true
        },
        %{
          "order_type" => "sell",
          "platinum" => 55,
          "platform" => "pc",
          "user" => %{
            "status" => "ingame"
          },
          "visible" => true
        },
        %{
          "order_type" => "sell",
          "platinum" => 50,
          "platform" => "pc",
          "user" => %{
            "status" => "ingame"
          },
          "visible" => true
        },
        %{
          "order_type" => "sell",
          "platinum" => 60,
          "platform" => "pc",
          "user" => %{
            "status" => "ingame"
          },
          "visible" => true
        },
        %{
          "order_type" => "sell",
          "platinum" => 50,
          "platform" => "pc",
          "user" => %{
            "status" => "ingame"
          },
          "visible" => true
        }
      ]

      product2_market_orders = [
        %{
          "order_type" => "sell",
          "platinum" => 40,
          "platform" => "pc",
          "user" => %{
            "status" => "ingame"
          },
          "visible" => true
        },
        %{
          "order_type" => "sell",
          "platinum" => 50,
          "platform" => "pc",
          "user" => %{
            "status" => "ingame"
          },
          "visible" => true
        },
        %{
          "order_type" => "sell",
          "platinum" => 50,
          "platform" => "pc",
          "user" => %{
            "status" => "ingame"
          },
          "visible" => true
        },
        %{
          "order_type" => "sell",
          "platinum" => 60,
          "platform" => "pc",
          "user" => %{
            "status" => "ingame"
          },
          "visible" => true
        },
        %{
          "order_type" => "sell",
          "platinum" => 50,
          "platform" => "pc",
          "user" => %{
            "status" => "ingame"
          },
          "visible" => true
        }
      ]

      deps = [store: StoreMock, auction_house: AuctionHouseMock]

      StoreMock
      |> expect(:list_products, fn ^syndicate -> {:ok, [product1, product2]} end)
      |> expect(:save_order, fn ^id1, ^syndicate -> {:ok, id1} end)
      |> expect(:save_order, fn ^id2, ^syndicate -> {:ok, id1} end)

      AuctionHouseMock
      |> expect(:get_all_orders, fn ^product1_name -> {:ok, product1_market_orders} end)
      |> expect(:place_order, fn ^order1 -> {:ok, id1} end)
      |> expect(:get_all_orders, fn ^product2_name -> {:ok, product2_market_orders} end)
      |> expect(:place_order, fn ^order2 -> {:ok, id2} end)

      # Act

      actual = Interpreter.activate(syndicate, strategy, deps)
      expected = {:ok, :success}

      # Assert
      assert actual == expected
    end

    test "Returns partial success if some orders failed to be placed" do
      # Arrange
      syndicate = "red_veil"
      strategy = :top_five_average
      id1 = "54a74454e779892d5e5155d5"
      id2 = "some_invalid_id"
      product1_name = "Gleaming Blight"
      product2_name = "Eroding Blight"

      products = [
        %{
          "name" => product1_name,
          "id" => id1,
          "price" => 15
        },
        %{
          "name" => product2_name,
          "id" => id2,
          "price" => 15
        }
      ]

      order1 = %{
        "order_type" => "sell",
        "item_id" => id1,
        "platinum" => 15,
        "quantity" => 1,
        "mod_rank" => 0
      }

      order2 = %{
        "order_type" => "sell",
        "item_id" => id2,
        "platinum" => 15,
        "quantity" => 1,
        "mod_rank" => 0
      }

      product1_market_orders = [
        %{
          "order_type" => "sell",
          "platinum" => 15,
          "platform" => "pc",
          "user" => %{
            "status" => "ingame"
          },
          "visible" => true
        }
      ]

      product2_market_orders = [
        %{
          "order_type" => "sell",
          "platinum" => 15,
          "platform" => "pc",
          "user" => %{
            "status" => "ingame"
          },
          "visible" => true
        }
      ]

      deps = [store: StoreMock, auction_house: AuctionHouseMock]

      StoreMock
      |> expect(:list_products, fn ^syndicate -> {:ok, products} end)
      |> expect(:save_order, fn ^id1, ^syndicate -> {:ok, id1} end)

      AuctionHouseMock
      |> expect(:get_all_orders, fn ^product1_name -> {:ok, product1_market_orders} end)
      |> expect(:place_order, fn ^order1 -> {:ok, id1} end)
      |> expect(:get_all_orders, fn ^product2_name -> {:ok, product2_market_orders} end)
      |> expect(:place_order, fn ^order2 -> {:error, :invalid_item_id, order2} end)

      # Act

      actual = Interpreter.activate(syndicate, strategy, deps)
      expected = {:partial_success, failed_orders: [{:error, :invalid_item_id, order2}]}

      # Assert
      assert actual == expected
    end

    test "Returns error if it is unable to place any orders" do
      # Arrange
      syndicate = "red_veil"
      strategy = :top_five_average
      id1 = "54a74454e779892d5e5155d5"
      id2 = "some_invalid_id"
      product1_name = "Gleaming Blight"
      product2_name = "Eroding Blight"

      products = [
        %{
          "name" => "Gleaming Blight",
          "id" => id1,
          "price" => 15
        },
        %{
          "name" => "Eroding Blight",
          "id" => id2,
          "price" => 15
        }
      ]

      order1 = %{
        "order_type" => "sell",
        "item_id" => id1,
        "platinum" => 15,
        "quantity" => 1,
        "mod_rank" => 0
      }

      order2 = %{
        "order_type" => "sell",
        "item_id" => id2,
        "platinum" => 15,
        "quantity" => 1,
        "mod_rank" => 0
      }

      product1_market_orders = [
        %{
          "order_type" => "sell",
          "platinum" => 15,
          "platform" => "pc",
          "user" => %{
            "status" => "ingame"
          },
          "visible" => true
        }
      ]

      product2_market_orders = [
        %{
          "order_type" => "sell",
          "platinum" => 15,
          "platform" => "pc",
          "user" => %{
            "status" => "ingame"
          },
          "visible" => true
        }
      ]

      deps = [store: StoreMock, auction_house: AuctionHouseMock]

      StoreMock
      |> expect(:list_products, fn ^syndicate -> {:ok, products} end)

      AuctionHouseMock
      |> expect(:get_all_orders, fn ^product1_name -> {:ok, product1_market_orders} end)
      |> expect(:place_order, fn ^order1 -> {:error, :order_already_placed, order1} end)
      |> expect(:get_all_orders, fn ^product2_name -> {:ok, product2_market_orders} end)
      |> expect(:place_order, fn ^order2 -> {:error, :invalid_item_id, order2} end)

      # Act

      actual = Interpreter.activate(syndicate, strategy, deps)

      expected =
        {:error, :unable_to_place_requests,
         [
           {:error, :order_already_placed, order1},
           {:error, :invalid_item_id, order2}
         ]}

      # Assert
      assert actual == expected
    end
  end

  describe "deactivate/1" do
    test "Deletes orders from auction house and removes them from storage" do
      # Arrange
      syndicate = "red_veil"
      order_id1 = "54a74454e779892d5e5155d5"
      order_id2 = "54a74454e779892d5e5155a0"

      deps = [store: StoreMock, auction_house: AuctionHouseMock]

      StoreMock
      |> expect(:list_orders, fn ^syndicate -> {:ok, [order_id1, order_id2]} end)
      |> expect(:delete_order, fn ^order_id1, ^syndicate -> {:ok, order_id1} end)
      |> expect(:delete_order, fn ^order_id2, ^syndicate -> {:ok, order_id2} end)

      AuctionHouseMock
      |> expect(:delete_order, fn ^order_id1 -> {:ok, order_id1} end)
      |> expect(:delete_order, fn ^order_id2 -> {:ok, order_id2} end)

      # Act

      actual = Interpreter.deactivate(syndicate, deps)
      expected = {:ok, :success}

      # Assert
      assert actual == expected
    end

    test "Removes order from storage if it fails to delete it because it is :non_existent" do
      # Arrange
      syndicate = "red_veil"
      order_id1 = "54a74454e779892d5e5155d5"
      order_id2 = "bad_order_id"

      deps = [store: StoreMock, auction_house: AuctionHouseMock]

      StoreMock
      |> expect(:list_orders, fn ^syndicate -> {:ok, [order_id1, order_id2]} end)
      |> expect(:delete_order, fn ^order_id1, ^syndicate -> {:ok, order_id1} end)
      |> expect(:delete_order, fn ^order_id2, ^syndicate -> {:ok, order_id2} end)

      AuctionHouseMock
      |> expect(:delete_order, fn ^order_id1 -> {:ok, order_id1} end)
      |> expect(:delete_order, fn ^order_id2 -> {:error, :order_non_existent, order_id2} end)

      # Act

      actual = Interpreter.deactivate(syndicate, deps)
      expected = {:partial_success, failed_orders: [{:error, :order_non_existent, order_id2}]}

      # Assert
      assert actual == expected
    end

    test "Returns error if it is unable to delete any orders" do
      # Arrange
      syndicate = "red_veil"
      order_id1 = "54a74454e779892d5e5155d5"
      order_id2 = "54a74454e779892d5e5155d6"

      deps = [store: StoreMock, auction_house: AuctionHouseMock]

      StoreMock
      |> expect(:list_orders, fn ^syndicate -> {:ok, [order_id1, order_id2]} end)

      AuctionHouseMock
      |> expect(:delete_order, fn ^order_id1 -> {:error, :timeout, order_id1} end)
      |> expect(:delete_order, fn ^order_id2 -> {:error, :timeout, order_id2} end)

      # Act

      actual = Interpreter.deactivate(syndicate, deps)

      expected =
        {:error, :unable_to_delete_orders,
         [
           {:error, :timeout, order_id1},
           {:error, :timeout, order_id2}
         ]}

      # Assert
      assert actual == expected
    end
  end
end
