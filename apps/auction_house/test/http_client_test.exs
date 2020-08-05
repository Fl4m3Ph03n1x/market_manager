defmodule AuctionHouse.HTTPClientTest do
  use ExUnit.Case

  alias AuctionHouse.HTTPClient

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
        end,
        run_fn: fn _queue_name, func -> func.() end
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
             body: "{\"error\":{\"_form\":[\"app.post_order.already_created_no_duplicates\"]}}"
           }}
        end,
        run_fn: fn _queue_name, func -> func.() end
      ]

      # Act
      actual = HTTPClient.place_order(order, deps)
      expected = {:error, :order_already_placed, "54a74454e779892d5e5155d5"}

      # Assert
      assert actual == expected
    end

    test "returns error if item_id of order was invalid" do
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
             body: "{\"error\":{\"item_id\":[\"app.form.invalid\"]}}"
           }}
        end,
        run_fn: fn _queue_name, func -> func.() end
      ]

      # Act
      actual = HTTPClient.place_order(order, deps)
      expected = {:error, :invalid_item_id, "54a74454e779892d5e5155d5"}

      # Assert
      assert actual == expected
    end

    test "returns error if mod has no level and yet a level was passed" do
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
             body: "{\"error\":{\"mod_rank\":[\"app.form.invalid\"]}}"
           }}
        end,
        run_fn: fn _queue_name, func -> func.() end
      ]

      # Act
      actual = HTTPClient.place_order(order, deps)
      expected = {:error, :rank_level_non_applicable, "54a74454e779892d5e5155d5"}

      # Assert
      assert actual == expected
    end

    test "returns error if server is unavailable" do
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
             status_code: 503,
             body: "<html><head><title>503 Service Temporarily Unavailable</title></head></html>"
           }}
        end,
        run_fn: fn _queue_name, func -> func.() end
      ]

      # Act
      actual = HTTPClient.place_order(order, deps)
      expected = {:error, :server_unavailable, "54a74454e779892d5e5155d5"}

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
        end,
        run_fn: fn _queue_name, func -> func.() end
      ]

      # Act
      actual = HTTPClient.place_order(order, deps)
      expected = {:error, :timeout, "54a74454e779892d5e5155d5"}

      # Assert
      assert actual == expected
    end
  end

  describe "delete_oder/1" do
    test "returns {:ok, order_id} if order was deleted correctly" do
      # Arrange
      order_id = "5ee71a2604d55c0a5cbdc3c2"

      deps = [
        delete_fn: fn _url, _headers ->
          {:ok,
           %HTTPoison.Response{
             status_code: 200,
             body: "{\"payload\":{\"order_id\":\"5ee71a2604d55c0a5cbdc3c2\"}}"
           }}
        end,
        run_fn: fn _queue_name, func -> func.() end
      ]

      # Act
      actual = HTTPClient.delete_order(order_id, deps)
      expected = {:ok, "5ee71a2604d55c0a5cbdc3c2"}

      # Assert
      assert actual == expected
    end

    test "returns error if order did not exist" do
      # Arrange
      order_id = "5ee71a2604d55c0a5cbdc3c2"

      deps = [
        delete_fn: fn _url, _headers ->
          {:ok,
           %HTTPoison.Response{
             status_code: 400,
             body: "{\"error\": {\"order_id\": [\"app.form.invalid\"]}}"
           }}
        end,
        run_fn: fn _queue_name, func -> func.() end
      ]

      # Act
      actual = HTTPClient.delete_order(order_id, deps)
      expected = {:error, :order_non_existent, "5ee71a2604d55c0a5cbdc3c2"}

      # Assert
      assert actual == expected
    end

    test "returns error if a generic network error occurred while deleting a request" do
      # Arrange
      order_id = "5ee71a2604d55c0a5cbdc3c2"

      deps = [
        delete_fn: fn _url, _headers ->
          {:error, %HTTPoison.Error{id: nil, reason: :timeout}}
        end,
        run_fn: fn _queue_name, func -> func.() end
      ]

      # Act
      actual = HTTPClient.delete_order(order_id, deps)
      expected = {:error, :timeout, "5ee71a2604d55c0a5cbdc3c2"}

      # Assert
      assert actual == expected
    end
  end

  describe "get_all_orders/1" do
    test "returns {:ok, [order_info]} if request for orders about item succeeded" do
      # Arrange
      item_name = "Gleaming Blight"

      deps = [
        get_fn: fn _url, _headers ->
          {:ok,
           %HTTPoison.Response{
             status_code: 200,
             body: "{\"payload\":{\"orders\":[{\"order_type\":\"sell\",\"platform\":\"pc\",\"platinum\":45,\"region\":\"en\",\"user\":{\"status\":\"ingame\"},\"visible\":true},{\"order_type\":\"sell\",\"platform\":\"pc\",\"platinum\":30.0,\"region\":\"en\",\"user\":{\"status\":\"ingame\"},\"visible\":true}]}}"
           }}
        end,
        run_fn: fn _queue_name, func -> func.() end
      ]

      # Act
      actual = HTTPClient.get_all_orders(item_name, deps)
      expected = {:ok, [
        %{
          "order_type" => "sell",
          "platform" => "pc",
          "platinum" => 45,
          "region" => "en",
          "user" => %{"status" => "ingame"},
          "visible" => true
        },
        %{
          "order_type" => "sell",
          "platform" => "pc",
          "platinum" => 30.0,
          "region" => "en",
          "user" => %{"status" => "ingame"},
          "visible" => true
        }
      ]}

      # Assert
      assert actual == expected
    end
  end
end
