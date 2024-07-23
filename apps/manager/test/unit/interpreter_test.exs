defmodule Manager.InterpreterTest do
  @moduledoc false

  use ExUnit.Case

  import Mock

  alias Helpers
  alias Manager.Impl.Interpreter

  alias Shared.Data.{
    Authorization,
    Credentials,
    OrderInfo,
    PlacedOrder,
    Strategy,
    Syndicate,
    User
  }

  describe "activate/4" do
    setup do
      syndicate = Syndicate.new(name: "Red Veil", id: :red_veil, catalog: [])

      strategy =
        Strategy.new(
          name: "Top 5 Average",
          id: :top_five_average,
          description: "Gets the 5 lowest prices for the given item and calculates the average."
        )

      id1 = "54a74454e779892d5e5155d5"
      id2 = "54a74454e779892d5e5155a0"
      product1_name = "Gleaming Blight"
      product2_name = "Eroding Blight"
      invalid_id = "some_invalid_id"

      product1 = Helpers.create_product(name: product1_name, id: id1, rank: 0)
      product2 = Helpers.create_product(name: product2_name, id: id2)
      invalid_product = Helpers.create_product(name: product2_name, id: invalid_id)

      placed_order1 = Helpers.create_placed_order(item_id: product1.id)
      placed_order2 = Helpers.create_placed_order(item_id: product2.id)
      bad_placed_order = Helpers.create_placed_order(item_id: invalid_id)

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
            "status" => "ingame"
          },
          "visible" => true
        }),
        OrderInfo.new(%{
          "order_type" => "sell",
          "platinum" => 55,
          "platform" => "pc",
          "user" => %{
            "status" => "ingame"
          },
          "visible" => true
        }),
        OrderInfo.new(%{
          "order_type" => "sell",
          "platinum" => 50,
          "platform" => "pc",
          "user" => %{
            "status" => "ingame"
          },
          "visible" => true
        }),
        OrderInfo.new(%{
          "order_type" => "sell",
          "platinum" => 60,
          "platform" => "pc",
          "user" => %{
            "status" => "ingame"
          },
          "visible" => true
        }),
        OrderInfo.new(%{
          "order_type" => "sell",
          "platinum" => 50,
          "platform" => "pc",
          "user" => %{
            "status" => "ingame"
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
            "status" => "ingame"
          },
          "visible" => true
        }),
        OrderInfo.new(%{
          "order_type" => "sell",
          "platinum" => 50,
          "platform" => "pc",
          "user" => %{
            "status" => "ingame"
          },
          "visible" => true
        }),
        OrderInfo.new(%{
          "order_type" => "sell",
          "platinum" => 50,
          "platform" => "pc",
          "user" => %{
            "status" => "ingame"
          },
          "visible" => true
        }),
        OrderInfo.new(%{
          "order_type" => "sell",
          "platinum" => 60,
          "platform" => "pc",
          "user" => %{
            "status" => "ingame"
          },
          "visible" => true
        }),
        OrderInfo.new(%{
          "order_type" => "sell",
          "platinum" => 50,
          "platform" => "pc",
          "user" => %{
            "status" => "ingame"
          },
          "visible" => true
        })
      ]

      handle = fn content ->
        send(self(), content)
        :ok
      end

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
        product2_market_orders: product2_market_orders,
        placed_order1: placed_order1,
        placed_order2: placed_order2,
        bad_placed_order: bad_placed_order,
        handle: handle
      }
    end

    test "does not try to place an order in AuctionHouse if order for same item is already in Storage (duplicate order placement)",
         %{
           syndicate: syndicate,
           strategy: strategy,
           product1: product1,
           product2: product2,
           product2_name: product2_name,
           order2: order2,
           product2_market_orders: product2_market_orders,
           placed_order1: placed_order1,
           placed_order2: placed_order2,
           handle: handle
         } do
      with_mocks([
        {
          Store,
          [],
          [
            get_login_data: fn ->
              {:ok,
               {
                 %Authorization{token: "a_token", cookie: "a_cookie"},
                 %User{ingame_name: "username", patreon?: false}
               }}
            end,
            list_sell_orders: fn -> {:ok, %{manual: [], automatic: [placed_order1]}} end,
            list_products: fn _syndicate -> {:ok, [product1, product2]} end,
            save_order: fn _placed_order, _syndicate -> :ok end
          ]
        },
        {
          AuctionHouse,
          [],
          [
            recover_login: fn _auth, _user -> :ok end,
            get_user_order: fn _user ->
              {:ok,
               [
                 %PlacedOrder{
                   order_id: "66058313a9630600302d4889",
                   item_id: "55108594e77989728d5100c6"
                 },
                 %PlacedOrder{
                   order_id: "6605832ea96306003657a90d",
                   item_id: "54e644ffe779897594fa68d2"
                 }
               ]}
            end,
            get_all_orders: fn
              ^product2_name -> {:ok, product2_market_orders}
            end,
            place_order: fn
              ^order2 -> {:ok, placed_order2}
            end
          ]
        }
      ]) do
        # Act
        actual = Interpreter.activate(syndicate, strategy, handle)
        expected = :ok

        # Assert
        assert actual == expected

        assert_called(Store.list_products(syndicate))
        assert_called(Store.list_sell_orders())
        assert_called(Store.save_order(placed_order2, syndicate))

        assert_called(AuctionHouse.get_all_orders(product2_name))
        assert_called(AuctionHouse.place_order(order2))

        assert_received({:activate, ^syndicate, {1, 2, {:ok, ^placed_order1}}})
        assert_received({:activate, ^syndicate, {2, 2, {:ok, ^placed_order2}}})
        assert_received({:activate, ^syndicate, :done})
      end
    end

    # test "Places orders in auction house and saves placed_orders", %{
    #   syndicate: syndicate,
    #   strategy: strategy,
    #   product1: product1,
    #   product2: product2,
    #   product1_name: product1_name,
    #   product2_name: product2_name,
    #   order1: order1,
    #   order2: order2,
    #   product1_market_orders: product1_market_orders,
    #   product2_market_orders: product2_market_orders,
    #   placed_order1: placed_order1,
    #   placed_order2: placed_order2,
    #   handle: handle
    # } do
    #   with_mocks([
    #     {
    #       Store,
    #       [],
    #       [
    #         list_orders: fn _syndicate -> {:ok, []} end,
    #         list_products: fn _syndicate -> {:ok, [product1, product2]} end,
    #         save_order: fn _placed_order, _syndicate -> :ok end
    #       ]
    #     },
    #     {
    #       AuctionHouse,
    #       [],
    #       [
    #         get_all_orders: fn
    #           ^product1_name -> {:ok, product1_market_orders}
    #           ^product2_name -> {:ok, product2_market_orders}
    #         end,
    #         place_order: fn
    #           ^order1 -> {:ok, placed_order1}
    #           ^order2 -> {:ok, placed_order2}
    #         end
    #       ]
    #     }
    #   ]) do
    #     # Act
    #     actual = Interpreter.activate(syndicate, strategy, handle)
    #     expected = :ok
    #
    #     # Assert
    #     assert actual == expected
    #
    #     assert_called(Store.list_products(syndicate))
    #     assert_called(Store.save_order(placed_order1, syndicate))
    #     assert_called(Store.save_order(placed_order2, syndicate))
    #
    #     assert_called(AuctionHouse.get_all_orders(product1_name))
    #     assert_called(AuctionHouse.get_all_orders(product2_name))
    #     assert_called(AuctionHouse.place_order(order1))
    #     assert_called(AuctionHouse.place_order(order2))
    #
    #     assert_received({:activate, ^syndicate, {1, 2, {:ok, ^placed_order1}}})
    #     assert_received({:activate, ^syndicate, {2, 2, {:ok, ^placed_order2}}})
    #     assert_received({:activate, ^syndicate, :done})
    #   end
    # end
    #
    # test "Finishes normally if there are no products from Store", %{
    #   syndicate: syndicate,
    #   strategy: strategy,
    #   handle: handle
    # } do
    #   with_mocks([
    #     {
    #       Store,
    #       [],
    #       [
    #         list_orders: fn _syndicate -> {:ok, []} end,
    #         list_products: fn _syndicate -> {:ok, []} end
    #       ]
    #     }
    #   ]) do
    #     # Act
    #     actual = Interpreter.activate(syndicate, strategy, handle)
    #     expected = :ok
    #
    #     # Assert
    #     assert actual == expected
    #
    #     assert_called(Store.list_products(syndicate))
    #
    #     assert_received({:activate, ^syndicate, :done})
    #   end
    # end
    #
    # test "Succeeds even if it cannot get order_info from product", %{
    #   syndicate: syndicate,
    #   strategy: strategy,
    #   product1: product1,
    #   product2: product2,
    #   product1_name: product1_name,
    #   product2_name: product2_name,
    #   order1_without_market_info: order1,
    #   order2_without_market_info: order2,
    #   placed_order1: placed_order1,
    #   placed_order2: placed_order2,
    #   handle: handle
    # } do
    #   with_mocks([
    #     {
    #       Store,
    #       [],
    #       [
    #         list_orders: fn _syndicate -> {:ok, []} end,
    #         list_products: fn _syndicate -> {:ok, [product1, product2]} end,
    #         save_order: fn _placed_order, _syndicate -> :ok end
    #       ]
    #     },
    #     {
    #       AuctionHouse,
    #       [],
    #       [
    #         get_all_orders: fn
    #           product_name -> {:error, :timeout, product_name}
    #         end,
    #         place_order: fn
    #           ^order1 -> {:ok, placed_order1}
    #           ^order2 -> {:ok, placed_order2}
    #         end
    #       ]
    #     }
    #   ]) do
    #     # Act
    #     actual = Interpreter.activate(syndicate, strategy, handle)
    #     expected = :ok
    #
    #     # Assert
    #     assert actual == expected
    #
    #     assert_called(Store.list_products(syndicate))
    #     assert_called(Store.save_order(placed_order1, syndicate))
    #     assert_called(Store.save_order(placed_order2, syndicate))
    #
    #     assert_called(AuctionHouse.get_all_orders(product1_name))
    #     assert_called(AuctionHouse.get_all_orders(product2_name))
    #     assert_called(AuctionHouse.place_order(order1))
    #     assert_called(AuctionHouse.place_order(order2))
    #
    #     assert_received({:activate, ^syndicate, {1, 2, {:ok, ^placed_order1}}})
    #     assert_received({:activate, ^syndicate, {2, 2, {:ok, ^placed_order2}}})
    #     assert_received({:activate, ^syndicate, :done})
    #   end
    # end
    #
    # test "Continues even if some order placements failed in AuctionHouse", %{
    #   syndicate: syndicate,
    #   strategy: strategy,
    #   product1: product1,
    #   invalid_product: invalid_product,
    #   product1_name: product1_name,
    #   product2_name: product2_name,
    #   placed_order1: placed_order1,
    #   order1: order1,
    #   invalid_order: invalid_order,
    #   product1_market_orders: product1_market_orders,
    #   product2_market_orders: product2_market_orders,
    #   handle: handle
    # } do
    #   with_mocks([
    #     {
    #       Store,
    #       [],
    #       [
    #         list_orders: fn _syndicate -> {:ok, []} end,
    #         list_products: fn _syndicate -> {:ok, [product1, invalid_product]} end,
    #         save_order: fn _placed_order, _syndicate -> :ok end
    #       ]
    #     },
    #     {
    #       AuctionHouse,
    #       [],
    #       [
    #         get_all_orders: fn
    #           ^product1_name -> {:ok, product1_market_orders}
    #           ^product2_name -> {:ok, product2_market_orders}
    #         end,
    #         place_order: fn
    #           ^order1 -> {:ok, placed_order1}
    #           ^invalid_order -> {:error, :invalid_item_id, invalid_order}
    #         end
    #       ]
    #     }
    #   ]) do
    #     # Act
    #     actual = Interpreter.activate(syndicate, strategy, handle)
    #     expected = :ok
    #
    #     # Assert
    #     assert actual == expected
    #
    #     assert_called(Store.list_products(syndicate))
    #     assert_called(Store.save_order(placed_order1, syndicate))
    #
    #     assert_received({:activate, ^syndicate, {1, 2, {:ok, ^placed_order1}}})
    #
    #     assert_received(
    #       {:activate, ^syndicate, {2, 2, {:error, :invalid_item_id, ^invalid_order}}}
    #     )
    #
    #     assert_received({:activate, ^syndicate, :done})
    #   end
    # end
    #
    # test "Finishes even if it was unable to place any orders in AuctionHouse", %{
    #   syndicate: syndicate,
    #   strategy: strategy,
    #   product1: product1,
    #   product2: product2,
    #   product1_name: product1_name,
    #   product2_name: product2_name,
    #   order1: order1,
    #   order2: order2,
    #   product1_market_orders: product1_market_orders,
    #   product2_market_orders: product2_market_orders,
    #   handle: handle
    # } do
    #   with_mocks([
    #     {
    #       Store,
    #       [],
    #       [
    #         list_orders: fn _syndicate -> {:ok, []} end,
    #         list_products: fn _syndicate -> {:ok, [product1, product2]} end
    #       ]
    #     },
    #     {
    #       AuctionHouse,
    #       [],
    #       [
    #         get_all_orders: fn
    #           ^product1_name -> {:ok, product1_market_orders}
    #           ^product2_name -> {:ok, product2_market_orders}
    #         end,
    #         place_order: fn
    #           ^order1 -> {:error, :order_already_placed, order1}
    #           ^order2 -> {:error, :invalid_item_id, order2}
    #         end
    #       ]
    #     }
    #   ]) do
    #     # Act
    #     actual = Interpreter.activate(syndicate, strategy, handle)
    #
    #     expected = :ok
    #
    #     # Assert
    #     assert actual == expected
    #
    #     assert_called(Store.list_products(syndicate))
    #     assert_not_called(Store.save_order(:_, :_))
    #     assert_received({:activate, ^syndicate, {1, 2, {:error, :order_already_placed, ^order1}}})
    #     assert_received({:activate, ^syndicate, {2, 2, {:error, :invalid_item_id, ^order2}}})
    #     assert_received({:activate, ^syndicate, :done})
    #   end
    # end
    #
    # test "Finishes immediately if it cannot read products from Store", %{
    #   syndicate: syndicate,
    #   strategy: strategy,
    #   handle: handle
    # } do
    #   with_mocks([
    #     {
    #       Store,
    #       [],
    #       [
    #         list_orders: fn _syndicate -> {:ok, []} end,
    #         list_products: fn _syndicate -> {:error, :enoent} end
    #       ]
    #     }
    #   ]) do
    #     # Act
    #     actual = Interpreter.activate(syndicate, strategy, handle)
    #     expected = :ok
    #
    #     # Assert
    #     assert actual == expected
    #
    #     assert_called(Store.list_products(syndicate))
    #     assert_not_called(Store.save_order(:_, :_))
    #
    #     assert_received({:activate, ^syndicate, {:error, :enoent}})
    #     assert_received({:activate, ^syndicate, :done})
    #   end
    # end
  end

  # describe "deactivate/3" do
  #   setup do
  #     syndicate = Syndicate.new(name: "Red Veil", id: :red_veil, catalog: [])
  #
  #     placed_order1 =
  #       PlacedOrder.new(%{
  #         "item_id" => "6214e890e3c4660048a8b980",
  #         "order_id" => "54a74454e779892d5e5155d5"
  #       })
  #
  #     placed_order2 =
  #       PlacedOrder.new(%{
  #         "item_id" => "5ea087d1c160d001303f9ed8",
  #         "order_id" => "54a74454e779892d5e5155a0"
  #       })
  #
  #     bad_placed_order =
  #       PlacedOrder.new(%{"item_id" => "5ea087d1c160d001303f9ed8", "order_id" => "bad_id"})
  #
  #     handle = fn content ->
  #       send(self(), content)
  #       :ok
  #     end
  #
  #     %{
  #       syndicate: syndicate,
  #       placed_order1: placed_order1,
  #       placed_order2: placed_order2,
  #       bad_placed_order: bad_placed_order,
  #       handle: handle
  #     }
  #   end
  #
  #   test "Deletes orders from auction house and removes them from storage", %{
  #     syndicate: syndicate,
  #     placed_order1: placed_order1,
  #     placed_order2: placed_order2,
  #     handle: handle
  #   } do
  #     with_mocks([
  #       {
  #         Store,
  #         [],
  #         [
  #           list_orders: fn _syndicate -> {:ok, [placed_order1, placed_order2]} end,
  #           delete_order: fn _order_id, _syndicate -> :ok end
  #         ]
  #       },
  #       {
  #         AuctionHouse,
  #         [],
  #         [
  #           delete_order: fn _placed_order -> :ok end
  #         ]
  #       }
  #     ]) do
  #       # Act
  #       actual = Interpreter.deactivate(syndicate, handle)
  #       expected = :ok
  #
  #       # Assert
  #       assert actual == expected
  #       assert_called(Store.list_orders(syndicate))
  #       assert_called(Store.delete_order(placed_order1, syndicate))
  #       assert_called(Store.delete_order(placed_order2, syndicate))
  #
  #       assert_called(AuctionHouse.delete_order(placed_order1))
  #       assert_called(AuctionHouse.delete_order(placed_order2))
  #
  #       assert_received({:deactivate, ^syndicate, {1, 2, {:ok, ^placed_order1}}})
  #       assert_received({:deactivate, ^syndicate, {2, 2, {:ok, ^placed_order2}}})
  #       assert_received({:deactivate, ^syndicate, :done})
  #     end
  #   end
  #
  #   test "Removes order from storage if it fails to delete it because it is :non_existent", %{
  #     syndicate: syndicate,
  #     placed_order1: placed_order1,
  #     bad_placed_order: bad_placed_order,
  #     handle: handle
  #   } do
  #     with_mocks([
  #       {
  #         Store,
  #         [],
  #         [
  #           list_orders: fn _syndicate -> {:ok, [placed_order1, bad_placed_order]} end,
  #           delete_order: fn _placed_order, _syndicate -> :ok end
  #         ]
  #       },
  #       {
  #         AuctionHouse,
  #         [],
  #         [
  #           delete_order: fn
  #             ^bad_placed_order -> {:error, :order_non_existent, bad_placed_order}
  #             ^placed_order1 -> :ok
  #           end
  #         ]
  #       }
  #     ]) do
  #       # Act
  #       actual = Interpreter.deactivate(syndicate, handle)
  #       expected = :ok
  #
  #       # Assert
  #       assert actual == expected
  #       assert_called(Store.list_orders(syndicate))
  #       assert_called(Store.delete_order(placed_order1, syndicate))
  #       assert_called(Store.delete_order(bad_placed_order, syndicate))
  #
  #       assert_called(AuctionHouse.delete_order(placed_order1))
  #       assert_called(AuctionHouse.delete_order(bad_placed_order))
  #
  #       assert_received({:deactivate, ^syndicate, {1, 2, {:ok, ^placed_order1}}})
  #       assert_received({:deactivate, ^syndicate, {2, 2, {:ok, ^bad_placed_order}}})
  #       assert_received({:deactivate, ^syndicate, :done})
  #     end
  #   end
  #
  #   test "Returns error if it fails to delete an order in auction_house and then fails to delete it in storage",
  #        %{
  #          syndicate: syndicate,
  #          placed_order1: placed_order1,
  #          bad_placed_order: bad_placed_order,
  #          handle: handle
  #        } do
  #     with_mocks([
  #       {
  #         Store,
  #         [],
  #         [
  #           list_orders: fn _syndicate -> {:ok, [placed_order1, bad_placed_order]} end,
  #           delete_order: fn
  #             ^placed_order1, _syndicate -> :ok
  #             ^bad_placed_order, _syndicate -> {:error, :enoent}
  #           end
  #         ]
  #       },
  #       {
  #         AuctionHouse,
  #         [],
  #         [
  #           delete_order: fn
  #             ^bad_placed_order -> {:error, :order_non_existent, bad_placed_order}
  #             ^placed_order1 -> :ok
  #           end
  #         ]
  #       }
  #     ]) do
  #       # Act
  #       actual = Interpreter.deactivate(syndicate, handle)
  #       expected = :ok
  #
  #       # Assert
  #       assert actual == expected
  #       assert_called(Store.list_orders(syndicate))
  #       assert_called(Store.delete_order(placed_order1, syndicate))
  #       assert_called(Store.delete_order(bad_placed_order, syndicate))
  #
  #       assert_called(AuctionHouse.delete_order(placed_order1))
  #       assert_called(AuctionHouse.delete_order(bad_placed_order))
  #
  #       assert_received({:deactivate, ^syndicate, {1, 2, {:ok, ^placed_order1}}})
  #       assert_received({:deactivate, ^syndicate, {2, 2, {:error, :enoent, ^bad_placed_order}}})
  #       assert_received({:deactivate, ^syndicate, :done})
  #     end
  #   end
  #
  #   test "Returns error if it is unable to delete orders from auction house and it does NOT attempt to delete them from storage",
  #        %{
  #          syndicate: syndicate,
  #          placed_order1: placed_order1,
  #          placed_order2: placed_order2,
  #          handle: handle
  #        } do
  #     with_mocks([
  #       {
  #         Store,
  #         [],
  #         [
  #           list_orders: fn _syndicate -> {:ok, [placed_order1, placed_order2]} end
  #         ]
  #       },
  #       {
  #         AuctionHouse,
  #         [],
  #         [
  #           delete_order: fn placed_order -> {:error, :timeout, placed_order} end
  #         ]
  #       }
  #     ]) do
  #       # Act
  #       actual = Interpreter.deactivate(syndicate, handle)
  #       expected = :ok
  #
  #       # Assert
  #       assert actual == expected
  #
  #       assert_called(Store.list_orders(syndicate))
  #       assert_not_called(Store.delete_order(placed_order1, syndicate))
  #       assert_not_called(Store.delete_order(placed_order2, syndicate))
  #
  #       assert_called(AuctionHouse.delete_order(placed_order1))
  #       assert_called(AuctionHouse.delete_order(placed_order2))
  #
  #       assert_received({:deactivate, ^syndicate, {1, 2, {:error, :timeout, ^placed_order1}}})
  #
  #       assert_received({:deactivate, ^syndicate, {2, 2, {:error, :timeout, ^placed_order2}}})
  #
  #       assert_received({:deactivate, ^syndicate, :done})
  #     end
  #   end
  # end
  #
  describe "login/4" do
    setup do
      %{
        authorization: Authorization.new(%{"cookie" => "a_cookie", "token" => "a_token"}),
        user: User.new(%{"ingame_name" => "fl4m3", "patreon?" => false}),
        credentials: Credentials.new("username", "password"),
        handle: fn content ->
          send(self(), content)
          :ok
        end
      }
    end

    test "Returns ok if manual login  with `keep_logged_in == true` was successful and it saved data",
         %{
           authorization: auth,
           user: user,
           credentials: credentials,
           handle: handle
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
            login: fn _credentials -> {:ok, {auth, user}} end
          ]
        }
      ]) do
        # Arrange
        deps = [store: Store, auction_house: AuctionHouse]

        # Act
        actual = Interpreter.login(credentials, true, handle, deps)
        expected = :ok

        # Assert
        assert actual == expected

        assert_called(AuctionHouse.login(credentials))
        assert_not_called(AuctionHouse.recover_login(:_))

        assert_called(Store.save_login_data(auth, user))

        assert_received({:login, ^user, :done})
      end
    end

    test "Returns error if manual login  with `keep_logged_in == true` was successful but failed to save data",
         %{
           authorization: auth,
           user: user,
           credentials: credentials,
           handle: handle
         } do
      with_mocks([
        {
          Store,
          [],
          [
            save_login_data: fn _auth, _user -> {:error, :enoent} end
          ]
        },
        {
          AuctionHouse,
          [],
          [
            login: fn _credentials -> {:ok, {auth, user}} end
          ]
        }
      ]) do
        # Arrange
        deps = [store: Store, auction_house: AuctionHouse]

        # Act
        actual = Interpreter.login(credentials, true, handle, deps)
        expected = :ok

        # Assert
        assert actual == expected

        assert_called(AuctionHouse.login(credentials))
        assert_not_called(AuctionHouse.recover_login(:_))

        assert_called(Store.save_login_data(auth, user))

        assert_received({:login, ^credentials, {:error, :enoent}})
      end
    end

    test "Returns ok if manual login  with `keep_logged_in == false` was successful and it deleted data",
         %{
           authorization: auth,
           user: user,
           credentials: credentials,
           handle: handle
         } do
      with_mocks([
        {
          Store,
          [],
          [
            delete_login_data: fn -> :ok end,
            get_login_data: fn -> {:ok, nil} end
          ]
        },
        {
          AuctionHouse,
          [],
          [
            login: fn _credentials -> {:ok, {auth, user}} end
          ]
        }
      ]) do
        # Arrange
        deps = [store: Store, auction_house: AuctionHouse]

        # Act
        actual = Interpreter.login(credentials, false, handle, deps)
        expected = :ok

        # Assert
        assert actual == expected

        assert_called(AuctionHouse.login(credentials))
        assert_not_called(AuctionHouse.recover_login(:_))

        assert_called(Store.delete_login_data())
        assert_not_called(Store.get_login_data())
        assert_not_called(Store.save_login_data(:_, :_))

        assert_received({:login, ^user, :done})
      end
    end

    test "Returns error if manual login with `keep_logged_in == false` was successful but it failed to delete data",
         %{
           authorization: auth,
           user: user,
           credentials: credentials,
           handle: handle
         } do
      with_mocks([
        {
          Store,
          [],
          [
            delete_login_data: fn -> {:error, :enoent} end,
            get_login_data: fn -> {:ok, nil} end
          ]
        },
        {
          AuctionHouse,
          [],
          [
            login: fn _credentials -> {:ok, {auth, user}} end
          ]
        }
      ]) do
        # Arrange
        deps = [store: Store, auction_house: AuctionHouse]

        # Act
        actual = Interpreter.login(credentials, false, handle, deps)
        expected = :ok

        # Assert
        assert actual == expected

        assert_called(AuctionHouse.login(credentials))
        assert_not_called(AuctionHouse.recover_login(:_))

        assert_called(Store.delete_login_data())
        assert_not_called(Store.get_login_data())
        assert_not_called(Store.save_login_data(:_, :_))

        assert_received({:login, ^credentials, {:error, :enoent}})
      end
    end

    test "Returns error if manual login failed", %{
      credentials: credentials,
      handle: handle
    } do
      with_mocks([
        {
          Store,
          [],
          [
            save_login_data: fn _auth, _user -> {:error, :enoent} end
          ]
        },
        {
          AuctionHouse,
          [],
          [
            login: fn _credentials -> {:error, :timeout, credentials} end
          ]
        }
      ]) do
        # Arrange
        deps = [store: Store, auction_house: AuctionHouse]

        # Act
        actual = Interpreter.login(credentials, true, handle, deps)
        expected = :ok

        # Assert
        assert actual == expected

        assert_called(AuctionHouse.login(credentials))

        assert_not_called(Store.save_login_data(:_, :_))
        assert_not_called(Store.delete_login_data())

        assert_received({:login, ^credentials, {:error, :timeout, ^credentials}})
      end
    end
  end

  describe "recover_login/1" do
    setup do
      %{
        authorization: Authorization.new(%{"cookie" => "a_cookie", "token" => "a_token"}),
        user: User.new(%{"ingame_name" => "fl4m3", "patreon?" => false})
      }
    end

    test "Returns ok if automatic login was successful", %{
      authorization: auth,
      user: user
    } do
      with_mocks([
        {
          Store,
          [],
          [
            get_login_data: fn -> {:ok, {auth, user}} end
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
        # Arrange
        deps = [store: Store, auction_house: AuctionHouse]

        # Act
        actual = Interpreter.recover_login(deps)
        expected = {:ok, user}

        # Assert
        assert actual == expected

        assert_called(AuctionHouse.recover_login(auth, user))
        assert_not_called(AuctionHouse.login(:_))

        assert_called(Store.get_login_data())
      end
    end

    test "Returns nil if automatic login has no login info" do
      with_mocks([
        {
          Store,
          [],
          [
            get_login_data: fn -> {:ok, nil} end,
            save_login_data: fn _auth, _user -> :ok end
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
        # Arrange
        deps = [store: Store, auction_house: AuctionHouse]

        # Act
        actual = Interpreter.recover_login(deps)
        expected = {:ok, nil}

        # Assert
        assert actual == expected

        assert_not_called(AuctionHouse.recover_login(:_, :_))
        assert_not_called(AuctionHouse.login(:_))

        assert_called(Store.get_login_data())
        assert_not_called(Store.save_login_data(:_, :_))
      end
    end

    test "Returns error if automatic login fails" do
      with_mocks([
        {
          Store,
          [],
          [
            get_login_data: fn -> {:error, :enoent} end
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
        # Arrange
        deps = [store: Store, auction_house: AuctionHouse]

        # Act
        actual = Interpreter.recover_login(deps)
        expected = {:error, :enoent}

        # Assert
        assert actual == expected

        assert_not_called(AuctionHouse.recover_login(:_, :_))

        assert_called(Store.get_login_data())
      end
    end
  end

  describe "logout/1" do
    test "returns OK if logout is successful" do
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
            logout: fn -> :ok end
          ]
        }
      ]) do
        # Arrange
        deps = [store: Store, auction_house: AuctionHouse]

        # Act
        actual = Interpreter.logout(deps)
        expected = :ok

        # Assert
        assert actual == expected

        assert_called(AuctionHouse.logout())

        assert_called(Store.delete_login_data())
      end
    end

    test "returns error if it fails to delete session from file but still deletes session from memory" do
      with_mocks([
        {
          Store,
          [],
          [
            delete_login_data: fn -> {:error, :enoent} end
          ]
        },
        {
          AuctionHouse,
          [],
          [
            logout: fn -> :ok end
          ]
        }
      ]) do
        # Arrange
        deps = [store: Store, auction_house: AuctionHouse]

        # Act
        actual = Interpreter.logout(deps)
        expected = {:error, :enoent}

        # Assert
        assert actual == expected

        assert_called(AuctionHouse.logout())

        assert_called(Store.delete_login_data())
      end
    end

    test "returns error if it fails to delete session from memory and does not attempt to delete it from file" do
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
            logout: fn -> {:error, :reason} end
          ]
        }
      ]) do
        # Arrange
        deps = [store: Store, auction_house: AuctionHouse]

        # Act
        actual = Interpreter.logout(deps)
        expected = {:error, :reason}

        # Assert
        assert actual == expected

        assert_called(AuctionHouse.logout())

        assert_not_called(Store.delete_login_data())
      end
    end
  end

  describe "syndicates/1" do
    setup do
      %{
        syndicates: [
          Syndicate.new(name: "Red Veil", id: :red_veil, catalog: []),
          Syndicate.new(name: "New Loka", id: :new_loka, catalog: [])
        ]
      }
    end

    test "returns the list of known syndicates", %{syndicates: syndicates} do
      with_mocks([
        {Store, [], [list_syndicates: fn -> {:ok, syndicates} end]}
      ]) do
        # Act
        actual = Interpreter.syndicates()
        expected = {:ok, syndicates}

        # Assert
        assert actual == expected
        assert_called(Store.list_syndicates())
      end
    end

    test "returns error if it cannot return syndicate list" do
      with_mocks([
        {Store, [], [list_syndicates: fn -> {:error, :enoent} end]}
      ]) do
        # Act
        actual = Interpreter.syndicates()
        expected = {:error, :enoent}

        # Assert
        assert actual == expected
        assert_called(Store.list_syndicates())
      end
    end
  end

  describe "active_syndicates/1" do
    setup do
      %{
        active_syndicates: [
          Syndicate.new(name: "Red Veil", id: :red_veil, catalog: []),
          Syndicate.new(name: "New Loka", id: :new_loka, catalog: [])
        ]
      }
    end

    test "returns the list of currently active syndicates", %{active_syndicates: syndicates} do
      with_mocks([
        {Store, [], [list_active_syndicates: fn -> {:ok, syndicates} end]}
      ]) do
        # Act
        actual = Interpreter.active_syndicates()
        expected = {:ok, syndicates}

        # Assert
        assert actual == expected
        assert_called(Store.list_active_syndicates())
      end
    end

    test "returns error if it cannot return active syndicate list" do
      with_mocks([
        {Store, [], [list_active_syndicates: fn -> {:error, :enoent} end]}
      ]) do
        # Act
        actual = Interpreter.active_syndicates()
        expected = {:error, :enoent}

        # Assert
        assert actual == expected
        assert_called(Store.list_active_syndicates())
      end
    end
  end

  describe "strategies/0" do
    test "returns the list of available strategies" do
      # Arrange
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

      # Act
      actual = Interpreter.strategies()
      expected = {:ok, expected_strategies}

      # Assert
      assert actual == expected
    end
  end
end
