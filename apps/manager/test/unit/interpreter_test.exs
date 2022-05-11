defmodule Manager.InterpreterTest do
  use ExUnit.Case

  import Mock

  alias Helpers
  alias Manager.Impl.Interpreter

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

  describe "activate/3" do
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

        handle = fn content ->
          send(self(), content)
          :ok
        end

        # Act
        actual = Interpreter.activate(syndicate, strategy, handle, deps)
        expected = :ok

        # Assert
        assert actual == expected

        assert_called(Store.list_products(syndicate))
        assert_called(Store.save_order(id1, syndicate))
        assert_called(Store.save_order(id2, syndicate))

        assert_called(AuctionHouse.get_all_orders(product1_name))
        assert_called(AuctionHouse.get_all_orders(product2_name))
        assert_called(AuctionHouse.place_order(order1))
        assert_called(AuctionHouse.place_order(order2))

        assert_received({:activate, {1, 2, {:ok, "54a74454e779892d5e5155d5"}}})
        assert_received({:activate, {2, 2, {:ok, "54a74454e779892d5e5155a0"}}})
        assert_received({:activate, :done})
      end
    end

    test "Finishes normally if there are no products from Store", %{
      syndicate: syndicate,
      strategy: strategy
    } do
      with_mocks([
        {
          Store,
          [],
          [
            list_products: fn _syndicate -> {:ok, []} end,
            save_order: fn id, _syndicate -> {:ok, id} end
          ]
        }
      ]) do
        # Arrange
        deps = [store: Store]

        handle = fn content ->
          send(self(), content)
          :ok
        end

        # Act
        actual = Interpreter.activate(syndicate, strategy, handle, deps)
        expected = :ok

        # Assert
        assert actual == expected

        assert_called(Store.list_products(syndicate))
        assert_not_called(Store.save_order(:_, :_))

        assert_received({:activate, :done})
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
      order2_without_market_info: order2
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
        handle = fn content ->
          send(self(), content)
          :ok
        end

        deps = [store: Store, auction_house: AuctionHouse]

        # Act
        actual = Interpreter.activate(syndicate, strategy, handle, deps)
        expected = :ok

        # Assert
        assert actual == expected

        assert_called(Store.list_products(syndicate))
        assert_called(Store.save_order(id1, syndicate))
        assert_called(Store.save_order(id2, syndicate))

        assert_called(AuctionHouse.get_all_orders(product1_name))
        assert_called(AuctionHouse.get_all_orders(product2_name))
        assert_called(AuctionHouse.place_order(order1))
        assert_called(AuctionHouse.place_order(order2))

        assert_received({:activate, {1, 2, {:ok, "54a74454e779892d5e5155d5"}}})
        assert_received({:activate, {2, 2, {:ok, "54a74454e779892d5e5155a0"}}})
        assert_received({:activate, :done})
      end
    end

    test "Continues even if some order placements failed in AuctionHouse", %{
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
        handle = fn content ->
          send(self(), content)
          :ok
        end

        deps = [store: Store, auction_house: AuctionHouse]

        # Act
        actual = Interpreter.activate(syndicate, strategy, handle, deps)
        expected = :ok

        # Assert
        assert actual == expected

        assert_called(Store.list_products(syndicate))
        assert_called(Store.save_order(id1, syndicate))

        assert_received({:activate, {1, 2, {:ok, "54a74454e779892d5e5155d5"}}})
        assert_received({:activate, {2, 2, {:error, :invalid_item_id, ^invalid_order}}})
        assert_received({:activate, :done})
      end
    end

    test "Finishes even if it was unable to place any orders in AuctionHouse", %{
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
            list_products: fn _syndicate -> {:ok, [product1, product2]} end
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
        handle = fn content ->
          send(self(), content)
          :ok
        end

        deps = [store: Store, auction_house: AuctionHouse]

        # Act
        actual = Interpreter.activate(syndicate, strategy, handle, deps)

        expected = :ok

        # Assert
        assert actual == expected

        assert_called(Store.list_products(syndicate))
        assert_not_called(Store.save_order(:_, :_))
        assert_received({:activate, {1, 2, {:error, :order_already_placed, ^order1}}})
        assert_received({:activate, {2, 2, {:error, :invalid_item_id, ^order2}}})
        assert_received({:activate, :done})
      end
    end

    test "Finishes immediatly if it cannot read products from Store", %{
      syndicate: syndicate,
      strategy: strategy
    } do
      with_mocks([
        {
          Store,
          [],
          [
            list_products: fn _syndicate -> {:error, :enoent} end
          ]
        }
      ]) do
        # Arrange
        handle = fn content ->
          send(self(), content)
          :ok
        end

        deps = [store: Store]

        # Act
        actual = Interpreter.activate(syndicate, strategy, handle, deps)
        expected = :ok

        # Assert
        assert actual == expected

        assert_called(Store.list_products(syndicate))
        assert_not_called(Store.save_order(:_, :_))

        assert_received({:activate, {:error, :enoent}})
        assert_received({:activate, :done})
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

        handle = fn content ->
          send(self(), content)
          :ok
        end

        # Act
        actual = Interpreter.deactivate(syndicate, handle, deps)
        expected = :ok

        # Assert
        assert actual == expected
        assert_called(Store.list_orders(syndicate))
        assert_called(Store.delete_order(order_id1, syndicate))
        assert_called(Store.delete_order(order_id2, syndicate))

        assert_called(AuctionHouse.delete_order(order_id1))
        assert_called(AuctionHouse.delete_order(order_id2))

        assert_received({:deactivate, {1, 2, {:ok, "54a74454e779892d5e5155d5"}}})
        assert_received({:deactivate, {2, 2, {:ok, "54a74454e779892d5e5155a0"}}})
        assert_received({:deactivate, :done})
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
            delete_order: fn
              ^bad_order_id -> {:error, :order_non_existent, bad_order_id}
              order_id -> {:ok, order_id}
            end
          ]
        }
      ]) do
        # Arrange
        deps = [store: Store, auction_house: AuctionHouse]

        handle = fn content ->
          send(self(), content)
          :ok
        end

        # Act
        actual = Interpreter.deactivate(syndicate, handle, deps)
        expected = :ok

        # Assert
        assert actual == expected
        assert_called(Store.list_orders(syndicate))
        assert_called(Store.delete_order(order_id1, syndicate))
        assert_called(Store.delete_order(bad_order_id, syndicate))

        assert_called(AuctionHouse.delete_order(order_id1))
        assert_called(AuctionHouse.delete_order(bad_order_id))

        assert_received({:deactivate, {1, 2, {:ok, "54a74454e779892d5e5155d5"}}})
        assert_received({:deactivate, {2, 2, {:ok, "bad_order_id"}}})
        assert_received({:deactivate, :done})
      end
    end

    test "Returns error if it fails to delete an order in auction_house and then fails to delete it in storage",
         %{
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
            delete_order: fn
              ^order_id1, _syndicate -> {:ok, order_id1}
              ^bad_order_id, _syndicate -> {:error, :enoent}
            end
          ]
        },
        {
          AuctionHouse,
          [],
          [
            delete_order: fn
              ^bad_order_id -> {:error, :order_non_existent, bad_order_id}
              order_id -> {:ok, order_id}
            end
          ]
        }
      ]) do
        # Arrange
        deps = [store: Store, auction_house: AuctionHouse]

        handle = fn content ->
          send(self(), content)
          :ok
        end

        # Act
        actual = Interpreter.deactivate(syndicate, handle, deps)
        expected = :ok

        # Assert
        assert actual == expected
        assert_called(Store.list_orders(syndicate))
        assert_called(Store.delete_order(order_id1, syndicate))
        assert_called(Store.delete_order(bad_order_id, syndicate))

        assert_called(AuctionHouse.delete_order(order_id1))
        assert_called(AuctionHouse.delete_order(bad_order_id))

        assert_received({:deactivate, {1, 2, {:ok, "54a74454e779892d5e5155d5"}}})
        assert_received({:deactivate, {2, 2, {:error, :enoent, "bad_order_id"}}})
        assert_received({:deactivate, :done})
      end
    end

    test "Returns error if it is unable to delete orders from auction house and it does NOT attempt to delete them from storage",
         %{
           syndicate: syndicate,
           order_id1: order_id1,
           order_id2: order_id2
         } do
      with_mocks([
        {
          Store,
          [],
          [
            list_orders: fn _syndicate -> {:ok, [order_id1, order_id2]} end
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

        handle = fn content ->
          send(self(), content)
          :ok
        end

        # Act
        actual = Interpreter.deactivate(syndicate, handle, deps)
        expected = :ok

        # Assert
        assert actual == expected

        assert_called(Store.list_orders(syndicate))
        assert_not_called(Store.delete_order(order_id1, syndicate))
        assert_not_called(Store.delete_order(order_id2, syndicate))

        assert_called(AuctionHouse.delete_order(order_id1))
        assert_called(AuctionHouse.delete_order(order_id2))

        assert_received({:deactivate, {1, 2, {:error, :timeout, "54a74454e779892d5e5155d5"}}})
        assert_received({:deactivate, {2, 2, {:error, :timeout, "54a74454e779892d5e5155a0"}}})
        assert_received({:deactivate, :done})
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
            save_credentials: fn login_info -> {:ok, login_info} end
          ]
        },
        {
          AuctionHouse,
          [],
          [
            update_credentials: fn credentials -> {:ok, credentials} end
          ]
        }
      ]) do
        # Arrange
        deps = [store: Store, auction_house: AuctionHouse]
        login_info = %{"token" => "123", "cookie" => "abc"}

        # Act
        actual = Interpreter.authenticate(login_info, deps)
        expected = {:ok, login_info}

        # Assert
        assert actual == expected

        assert_called(AuctionHouse.update_credentials(login_info))
        assert_called(Store.save_credentials(login_info))
      end
    end

    test "Returns error if login info is missing one parameter" do
      with_mocks([
        {
          Store,
          [],
          [
            save_credentials: fn login_info -> {:ok, login_info} end
          ]
        },
        {
          AuctionHouse,
          [],
          [
            update_credentials: fn credentials -> {:ok, credentials} end
          ]
        }
      ]) do
        # Arrange
        deps = [store: Store, auction_house: AuctionHouse]
        login_info = %{"cookie" => "abc"}

        # Act
        actual = Interpreter.authenticate(login_info, deps)

        expected =
          {:error, :unable_to_save_authentication,
           {:missing_mandatory_keys, ["token"], login_info}}

        # Assert
        assert actual == expected

        assert_not_called(AuctionHouse.update_credentials(login_info))
        assert_not_called(Store.save_credentials(login_info))
      end
    end

    test "Returns error if login info is missing multiple parameters" do
      with_mocks([
        {
          Store,
          [],
          [
            save_credentials: fn login_info -> {:ok, login_info} end
          ]
        },
        {
          AuctionHouse,
          [],
          [
            update_credentials: fn credentials -> {:ok, credentials} end
          ]
        }
      ]) do
        # Arrange
        deps = [store: Store, auction_house: AuctionHouse]
        login_info = %{}

        # Act
        actual = Interpreter.authenticate(login_info, deps)

        expected =
          {:error, :unable_to_save_authentication,
           {:missing_mandatory_keys, ["cookie", "token"], login_info}}

        # Assert
        assert actual == expected

        assert_not_called(AuctionHouse.update_credentials(login_info))
        assert_not_called(Store.save_credentials(login_info))
      end
    end

    test "Returns error if login info is correct but fails to persist data" do
      with_mocks([
        {
          Store,
          [],
          [
            save_credentials: fn _login_info -> {:error, :enoent} end
          ]
        },
        {
          AuctionHouse,
          [],
          [
            update_credentials: fn credentials -> {:ok, credentials} end
          ]
        }
      ]) do
        # Arrange
        deps = [store: Store, auction_house: AuctionHouse]
        login_info = %{"token" => "123", "cookie" => "abc"}

        # Act
        actual = Interpreter.authenticate(login_info, deps)
        expected = {:error, :unable_to_save_authentication, {:enoent, login_info}}

        # Assert
        assert actual == expected

        assert_called(AuctionHouse.update_credentials(login_info))
        assert_called(Store.save_credentials(login_info))
      end
    end

    test "Returns error if it failed to update state in AuctionHouse" do
      with_mocks([
        {
          Store,
          [],
          [
            save_credentials: fn _login_info -> {:error, :enoent} end
          ]
        },
        {
          AuctionHouse,
          [],
          [
            update_credentials: fn _credentials -> {:error, :timeout} end
          ]
        }
      ]) do
        # Arrange
        deps = [store: Store, auction_house: AuctionHouse]
        login_info = %{"token" => "123", "cookie" => "abc"}

        # Act
        actual = Interpreter.authenticate(login_info, deps)
        expected = {:error, :unable_to_save_authentication, {:timeout, login_info}}

        # Assert
        assert actual == expected

        assert_called(AuctionHouse.update_credentials(login_info))
        assert_not_called(Store.save_credentials(login_info))
      end
    end
  end
end
