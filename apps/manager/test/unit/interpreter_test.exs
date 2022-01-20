defmodule Manager.InterpreterTest do
  use ExUnit.Case

  import Mock

  alias Manager.Interpreter

  describe "valid_action?/2" do
    test "Returns true if action is valid" do
      # Arrange
      action = "activate"

      # Act & Assert
      assert Interpreter.valid_action?(action)
    end

    test "Returns false if action is valid" do
      # Arrange
      action = "bad_action"

      # Act & Assert
      refute Interpreter.valid_action?(action)
    end
  end

  describe "activate/2" do

    setup do
      syndicate = "red_veil"
      strategy = :top_five_average
      id1 = "54a74454e779892d5e5155d5"
      id2 = "54a74454e779892d5e5155a0"
      product1_name = "Gleaming Blight"
      product2_name = "Eroding Blight"
      invalid_id = "some_invalid_id"

      product1 = create_product(product1_name, id1)
      product2 = create_product(product2_name, id2, "n/a")
      invalid_product = create_product(product2_name, invalid_id, "n/a")

      order1 = create_order(id1, 52, 0)
      order2 = create_order(id2, 50)
      invalid_order = create_order(invalid_id, 50)

      order1_without_market_info = %{
        "item_id" => "54a74454e779892d5e5155d5",
        "mod_rank" => 0,
        "order_type" => "sell",
        "platinum" => 16,
        "quantity" => 1
      }

      order2_without_market_info = %{
        "item_id" => "54a74454e779892d5e5155a0",
        "order_type" => "sell",
        "platinum" => 16,
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

    test "Places orders in auction house and saves order ids", %{
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
            save_order: fn id, _syndicate -> {:ok, id} end
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
            place_order: fn order -> {:ok, Map.get(order, "item_id")} end
          ]
        }
      ]) do
        # Arrange
        deps = [store: Store, auction_house: AuctionHouse]

        # Act
        actual = Interpreter.activate(syndicate, strategy, deps)
        expected = {:ok, :success}

        # Assert
        assert actual == expected

        assert_called Store.list_products(syndicate)
        assert_called Store.save_order(id1, syndicate)
        assert_called Store.save_order(id2, syndicate)

        assert_called AuctionHouse.get_all_orders(product1_name)
        assert_called AuctionHouse.get_all_orders(product2_name)
        assert_called AuctionHouse.place_order(order1)
        assert_called AuctionHouse.place_order(order2)
      end
    end

    test "Succeeds even if it cannot get order_info from product", %{
      syndicate: syndicate,
      strategy: strategy,
      product1: product1,
      product2: product2,
      product1_name: product1_name,
      product2_name: product2_name,
      id1: id1,
      id2: id2,
      order1_without_market_info: order1,
      order2_without_market_info: order2,
    } do
      with_mocks([
        {
          Store,
          [],
          [
            list_products: fn _syndicate -> {:ok, [product1, product2]} end,
            save_order: fn id, _syndicate -> {:ok, id} end
          ]
        },
        {
          AuctionHouse,
          [],
          [
            get_all_orders: fn
              product_name -> {:error, :timeout, product_name}
            end,
            place_order: fn order -> {:ok, Map.get(order, "item_id")} end
          ]
        }
      ]) do
        # Arrange
        deps = [store: Store, auction_house: AuctionHouse]

        # Act
        actual = Interpreter.activate(syndicate, strategy, deps)
        expected = {:ok, :success}

        # Assert
        assert actual == expected

        assert_called Store.list_products(syndicate)
        assert_called Store.save_order(id1, syndicate)
        assert_called Store.save_order(id2, syndicate)

        assert_called AuctionHouse.get_all_orders(product1_name)
        assert_called AuctionHouse.get_all_orders(product2_name)
        assert_called AuctionHouse.place_order(order1)
        assert_called AuctionHouse.place_order(order2)
      end
    end

    test "Returns partial success if some orders failed to be placed", %{
      syndicate: syndicate,
      strategy: strategy,
      product1: product1,
      invalid_product: invalid_product,
      product1_name: product1_name,
      product2_name: product2_name,
      id1: id1,
      order1: order1,
      invalid_order: invalid_order,
      product1_market_orders: product1_market_orders,
      product2_market_orders: product2_market_orders
    } do
      with_mocks([
        {
          Store,
          [],
          [
            list_products: fn _syndicate -> {:ok, [product1, invalid_product]} end,
            save_order: fn id, _syndicate -> {:ok, id} end
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
              ^order1 -> {:ok, id1}
              ^invalid_order -> {:error, :invalid_item_id, invalid_order}
            end
          ]
        }
      ]) do
        # Arrange
        deps = [store: Store, auction_house: AuctionHouse]

        # Act
        actual = Interpreter.activate(syndicate, strategy, deps)
        expected = {:partial_success, failed_orders: [{:error, :invalid_item_id, invalid_order}]}

        # Assert
        assert actual == expected

        assert_called Store.list_products(syndicate)
        assert_called Store.save_order(id1, syndicate)
      end
    end

    test "Returns error if it is unable to place any orders", %{
      syndicate: syndicate,
      strategy: strategy,
      product1: product1,
      product2: product2,
      product1_name: product1_name,
      product2_name: product2_name,
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
              ^order1 -> {:error, :order_already_placed, order1}
              ^order2 -> {:error, :invalid_item_id, order2}
            end
          ]
        }
      ]) do
        # Arrange
        deps = [store: Store, auction_house: AuctionHouse]

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

        assert_called Store.list_products(syndicate)
      end
    end
  end

  describe "deactivate/1" do

    setup do
      syndicate = "red_veil"
      order_id1 = "54a74454e779892d5e5155d5"
      order_id2 = "54a74454e779892d5e5155a0"
      bad_order_id = "bad_order_id"

      %{
        syndicate: syndicate,
        order_id1: order_id1,
        order_id2: order_id2,
        bad_order_id: bad_order_id
      }
    end

    test "Deletes orders from auction house and removes them from storage", %{
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
            delete_order: fn order_id, _syndicate -> {:ok, order_id} end
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
        # Arrange
        deps = [store: Store, auction_house: AuctionHouse]

        # Act
        actual = Interpreter.deactivate(syndicate, deps)
        expected = {:ok, :success}

        # Assert
        assert actual == expected
        assert_called Store.list_orders(syndicate)
        assert_called Store.delete_order(order_id1, syndicate)
        assert_called Store.delete_order(order_id2, syndicate)
        assert_called AuctionHouse.delete_order(order_id1)
        assert_called AuctionHouse.delete_order(order_id2)
      end
    end

    test "Removes order from storage if it fails to delete it because it is :non_existent", %{
      syndicate: syndicate,
      order_id1: order_id1,
      bad_order_id: bad_order_id
    } do
      with_mocks([
        {
          Store,
          [],
          [
            list_orders: fn _syndicate -> {:ok, [order_id1, bad_order_id]} end,
            delete_order: fn order_id, _syndicate -> {:ok, order_id} end
          ]
        },
        {
          AuctionHouse,
          [],
          [
            delete_order:
              fn
                ^bad_order_id -> {:error, :order_non_existent, bad_order_id}
                order_id -> {:ok, order_id}
              end
          ]
        }
      ]) do
        # Arrange
        deps = [store: Store, auction_house: AuctionHouse]

        # Act
        actual = Interpreter.deactivate(syndicate, deps)
        expected = {:partial_success, failed_orders: [{:error, :order_non_existent, bad_order_id}]}

        # Assert
        assert actual == expected
        assert_called Store.list_orders(syndicate)
        assert_called Store.delete_order(order_id1, syndicate)
        assert_called Store.delete_order(bad_order_id, syndicate)
        assert_called AuctionHouse.delete_order(order_id1)
        assert_called AuctionHouse.delete_order(bad_order_id)
      end
    end

    test "Returns error if it is unable to delete any orders", %{
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
          ]
        },
        {
          AuctionHouse,
          [],
          [
            delete_order: fn order_id -> {:error, :timeout, order_id} end
          ]
        }
      ]) do
        # Arrange
        deps = [store: Store, auction_house: AuctionHouse]

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
        assert_called Store.list_orders(syndicate)
        assert_called AuctionHouse.delete_order(order_id1)
        assert_called AuctionHouse.delete_order(order_id2)
      end
    end
  end

  describe "authenticate/1" do

    test "Returns ok tuple if login info is correct and it persisted data successfuly" do
      with_mocks([
        {
          Store,
          [],
          [
            save_credentials: fn login_info -> {:ok, login_info} end,
          ]
        }
      ]) do
        # Arrange
        deps = [store: Store]
        login_info = %{"token" => "123", "cookie" => "abc"}

        # Act
        actual = Interpreter.authenticate(login_info, deps)
        expected = {:ok, login_info}

        # Assert
        assert actual == expected

        assert_called Store.save_credentials(login_info)
      end
    end

    test "Returns error if login info is missing one parameter" do
      with_mocks([
        {
          Store,
          [],
          [
            save_credentials: fn login_info -> {:ok, login_info} end,
          ]
        }
      ]) do
        # Arrange
        deps = [store: Store]
        login_info = %{"cookie" => "abc"}

        # Act
        actual = Interpreter.authenticate(login_info, deps)
        expected =  {:error, :unable_to_save_authentication, {:missing_mandatory_keys, ["token"], login_info}}

        # Assert
        assert actual == expected

        assert_not_called Store.save_credentials(login_info)
      end
    end

    test "Returns error if login info is missing multiple parameters" do
      with_mocks([
        {
          Store,
          [],
          [
            save_credentials: fn login_info -> {:ok, login_info} end,
          ]
        }
      ]) do
        # Arrange
        deps = [store: Store]
        login_info = %{}

        # Act
        actual = Interpreter.authenticate(login_info, deps)
        expected = {:error, :unable_to_save_authentication, {:missing_mandatory_keys, ["cookie", "token"], login_info}}

        # Assert
        assert actual == expected

        assert_not_called Store.save_credentials(login_info)
      end
    end

    test "Returns error if login info is correct but fails to persist data" do
      with_mocks([
        {
          Store,
          [],
          [
            save_credentials: fn _login_info -> {:error, :enoent} end,
          ]
        }
      ]) do
        # Arrange
        deps = [store: Store]
        login_info = %{"token" => "123", "cookie" => "abc"}

        # Act
        actual = Interpreter.authenticate(login_info, deps)
        expected = {:error, :unable_to_save_authentication, {:enoent, login_info}}

        # Assert
        assert actual == expected

        assert_called Store.save_credentials(login_info)
      end
    end
  end

  #####################
  # Helper Functions  #
  #####################

  defp create_order(item_id, platinum), do:
      %{
        "order_type" => "sell",
        "item_id" => item_id,
        "platinum" => platinum,
        "quantity" => 1
      }

  defp create_order(item_id, platinum, rank), do:
    %{
      "order_type" => "sell",
      "item_id" => item_id,
      "platinum" => platinum,
      "quantity" => 1,
      "mod_rank" => rank
    }

  defp create_product(name, id), do:
    %{
      "name" => name,
      "id" => id,
      "min_price" => 15,
      "default_price" => 16
    }

  defp create_product(name, id, rank), do:
    %{
      "name" => name,
      "id" => id,
      "min_price" => 15,
      "default_price" => 16,
      "rank" => rank
    }
end
