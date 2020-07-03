defmodule HTTPClientTest do
  use ExUnit.Case

  alias MarketManager.AuctionHouse.HTTPClient

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

      deps = [
        post_fn: fn _url, _body, _headers ->
          {:ok,
           %HTTPoison.Response{
             status_code: 200,
             body: "{\"payload\":{\"order\":{\"id\":\"5ee71a2604d55c0a5cbdc3c2\"}}}"
           }}
        end
      ]

      # Act
      actual = HTTPClient.place_order(order, deps)
      expected = {:ok, "5ee71a2604d55c0a5cbdc3c2"}

      # Assert
      assert actual == expected
    end

    test "returns error if order was already placed" do
      # Arrange
      order = %{
        "order_type" => "sell",
        "item_id" => "54a74454e779892d5e5155d5",
        "platinum" => 15,
        "quantity" => 1,
        "mod_rank" => 0
      }

      deps = [
        post_fn: fn _url, _body, _headers ->
          {:ok,
           %HTTPoison.Response{
             status_code: 400,
             body: "{\"error\":{\"_form\":\"duplicated_order\"}}"
           }}
        end
      ]

      # Act
      actual = HTTPClient.place_order(order, deps)
      expected = {:error, :order_already_placed, "54a74454e779892d5e5155d5"}

      # Assert
      assert actual == expected
    end

    test "returns error if order received was invalid" do
      # Arrange
      order = %{
        "order_type" => "sell",
        "item_id" => "54a74454e779892d5e5155d5",
        "platinum" => 15,
        "quantity" => 1,
        "mod_rank" => 0
      }

      deps = [
        post_fn: fn _url, _body, _headers ->
          {:ok,
           %HTTPoison.Response{
             status_code: 400,
             body: "{\"error\":{\"item_id\":\"invalid_item_id\"}}"
           }}
        end
      ]

      # Act
      actual = HTTPClient.place_order(order, deps)
      expected = {:error, :invalid_item_id, "54a74454e779892d5e5155d5"}

      # Assert
      assert actual == expected
    end

    test "returns error if a generic network error occurred while placing a request" do
      # Arrange
      order = %{
        "order_type" => "sell",
        "item_id" => "54a74454e779892d5e5155d5",
        "platinum" => 15,
        "quantity" => 1,
        "mod_rank" => 0
      }

      deps = [
        post_fn: fn _url, _body, _headers ->
          {:error, %HTTPoison.Error{id: nil, reason: :timeout}}
        end
      ]

      # Act
      actual = HTTPClient.place_order(order, deps)
      expected = {:error, :timeout, "54a74454e779892d5e5155d5"}

      # Assert
      assert actual == expected
    end
  end
end
