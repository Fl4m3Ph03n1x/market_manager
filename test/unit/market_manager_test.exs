defmodule MarketManagerTest do
  use ExUnit.Case
  doctest MarketManager

  import Mox

  alias MarketManager.{AuctionHouseMock, StoreMock}

  # Make sure mocks are verified when the test exits
  setup :verify_on_exit!

  describe "activate/1" do
    test "Places orders in auction house and saves order ids" do
      # Setup
      syndicate = "red_veil"
      id1 = "54a74454e779892d5e5155d5"
      id2 = "54a74454e779892d5e5155a0"

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

      StoreMock
      |> expect(:get_products_from_syndicate, fn ^syndicate -> {:ok, products} end)
      |> expect(:save_order, fn ^id1 -> {:ok, :order_saved} end)
      |> expect(:save_order, fn ^id2 -> {:ok, :order_saved} end)

      AuctionHouseMock
      |> expect(:place_order, fn ^order1 -> {:ok, id1} end)
      |> expect(:place_order, fn ^order2 -> {:ok, id2} end)

      # Execution

      actual = MarketManager.activate(syndicate)
      expected = {:ok, :success}

      # Assertion
      assert actual == expected
    end

    test "Returns partial success and if some orders failed to be placed" do
      # Setup
      syndicate = "red_veil"
      id1 = "54a74454e779892d5e5155d5"
      id2 = "some_invalid_id"

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

      StoreMock
      |> expect(:get_products_from_syndicate, fn ^syndicate -> {:ok, products} end)
      |> expect(:save_order, fn ^id1 -> {:ok, :order_saved} end)

      AuctionHouseMock
      |> expect(:place_order, fn ^order1 -> {:ok, id1} end)
      |> expect(:place_order, fn ^order2 -> {:error, :invalid_item_id, order2} end)

      # Execution

      actual = MarketManager.activate(syndicate)
      expected = {:partial_success, failed_orders: [{:error, :invalid_item_id, order2}]}

      # Assertion
      assert actual == expected
    end

    test "Returns error if it is unable to place any requests" do
      # Setup
      syndicate = "red_veil"
      id1 = "54a74454e779892d5e5155d5"
      id2 = "some_invalid_id"

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

      StoreMock
      |> expect(:get_products_from_syndicate, fn ^syndicate -> {:ok, products} end)

      AuctionHouseMock
      |> expect(:place_order, fn ^order1 -> {:error, :order_already_placed, order1} end)
      |> expect(:place_order, fn ^order2 -> {:error, :invalid_item_id, order2} end)

      # Execution

      actual = MarketManager.activate(syndicate)

      expected =
        {:error, :unable_to_place_requests,
         [
           {:error, :order_already_placed, order1},
           {:error, :invalid_item_id, order2}
         ]}

      # Assertion
      assert actual == expected
    end
  end

  describe "deactivate/1" do
    test "Deletes items from auction house and removes them from storage" do
      # Setup
      syndicate = "red_veil"
      order_id1 = "54a74454e779892d5e5155d5"
      order_id2 = "54a74454e779892d5e5155a0"

      StoreMock
      |> expect(:list_orders, fn ^syndicate -> {:ok, [order_id1, order_id2]} end)
      |> expect(:delete_order, fn ^order_id1 -> {:ok, order_id1} end)
      |> expect(:delete_order, fn ^order_id2 -> {:ok, order_id2} end)

      AuctionHouseMock
      |> expect(:delete_order, fn ^order_id1 -> {:ok, order_id1} end)
      |> expect(:delete_order, fn ^order_id2 -> {:ok, order_id2} end)

      # Execution

      actual = MarketManager.deactivate(syndicate)
      expected = {:ok, :success}

      # Assertion
      assert actual == expected
    end

  end
end
