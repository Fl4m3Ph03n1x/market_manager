defmodule AuctionHouseTest do
  use ExUnit.Case

  alias AuctionHouse

  describe "place_oder/1" do
    test "returns {:ok, order_id} if order was placed correctly" do
      # Arrange
      order = %{
        "order_type" => "sell",
        "item_id" => "54a74454e779892d5e5155d5",
        "platinum" => 15,
        "quantity" => 1,
        "mod_rank" => 0
      }

      # Act
      actual = AuctionHouse.place_order(order)
      expected = {:ok, "5ee71a2604d55c0a5cbdc3c2"}

      # Assert
      assert actual == expected
    end
  end

  describe "delete_oder/1" do
    test "returns {:ok, order_id} if order was deleted correctly" do
      # Arrange
      order_id = "5ee71a2604d55c0a5cbdc3c2"

      # Act
      actual = AuctionHouse.delete_order(order_id)
      expected = {:ok, "5ee71a2604d55c0a5cbdc3c2"}

      # Assert
      assert actual == expected
    end
  end

  describe "get_all_orders/1" do
    test "returns {:ok, [order_info]} if request for orders about item succeeded" do
      # Arrange
      item_name = "Gleaming Blight"

      # Act
      actual = AuctionHouse.get_all_orders(item_name)
      expected = {:ok, [
        %{
          "order_type" => "sell",
          "platform" => "pc",
          "platinum" => 45,
          "region" => "en",
          "user" => %{
            "status" => "ingame",
            "avatar" => nil,
            "id" => "598c96d60f313948524a2b66",
            "ingame_name" => "Elect4k",
            "last_seen" => "2020-07-20T18:20:28.422+00:00",
            "region" => "en",
            "reputation" => 2,
            "reputation_bonus" => 0
            },
          "visible" => true,
          "creation_date" => "2019-01-05T20:52:40.000+00:00",
          "id" => "5c311918716c98021463eb32",
          "last_update" => "2019-04-01T09:39:58.000+00:00",
          "quantity" => 1
        },
        %{
          "order_type" => "sell",
          "platform" => "pc",
          "platinum" => 30.0,
          "region" => "en",
          "user" => %{
            "status" => "ingame",
            "avatar" => "user/avatar/55d77904e779893a9827aee2.png?9b0eed7b4885f4ec4275240b3035aa55",
            "id" => "55d77904e779893a9827aee2",
            "ingame_name" => "porottaja",
            "last_seen" => "2020-07-18T13:58:49.665+00:00",
            "region" => "en",
            "reputation" => 28,
            "reputation_bonus" => 0
          },
          "visible" => true,
          "creation_date" => "2019-02-08T22:11:22.000+00:00",
          "id" => "5c5dfe8a83d1620563a75a7d",
          "last_update" => "2020-07-02T14:53:06.000+00:00",
          "quantity" => 2
        }
      ]}

      # Assert
      assert actual == expected
    end
  end
end
