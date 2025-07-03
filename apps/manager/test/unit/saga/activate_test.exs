defmodule Manager.Saga.ActivateTest do
  @moduledoc false

  use ExUnit.Case

  import Mock

  alias AuctionHouse
  alias Helpers
  alias Manager.Saga.Activate

  alias Shared.Data.{
    Authorization,
    Product,
    User
  }

  alias Store

  @timeout 5000

  describe "handle_continue/2" do
    setup do
      syndicates_with_strategy = %{new_loka: :top_five_average, perrin_sequence: :top_three_average}
      from = self()
      authorization = %Authorization{token: "a_token", cookie: "a_cookie"}
      user = %User{ingame_name: "username", patreon?: false}

      %{
        syndicates_with_strategy: syndicates_with_strategy,
        from: from,
        auth: authorization,
        user: user,
        limit: 100
      }
    end

    test "sends :get_user_orders to client if authentication succeeds", %{
      syndicates_with_strategy: syndicates_with_strategy,
      from: from,
      auth: auth,
      user: user,
      limit: limit
    } do
      with_mocks([
        {
          Store,
          [],
          [
            activate_syndicates: fn syndicates_to_activate ->
              assert syndicates_to_activate == syndicates_with_strategy
              :ok
            end
          ]
        },
        {
          AuctionHouse,
          [],
          [
            get_saved_login: fn -> {:ok, {auth, user}} end,
            get_user_orders: fn a_user ->
              assert a_user == user.ingame_name
              :ok
            end
          ]
        }
      ]) do
        assert Activate.handle_continue(
                 nil,
                 %{
                   deps: %{store: Store, auction_house: AuctionHouse},
                   non_patreon_order_limit: 100,
                   args: %{syndicates_with_strategy: syndicates_with_strategy},
                   from: from
                 }
               ) ==
                 {:noreply,
                  %{
                    args: %{syndicates_with_strategy: syndicates_with_strategy},
                    user: user,
                    deps: %{store: Store, auction_house: AuctionHouse},
                    from: from,
                    non_patreon_order_limit: limit
                  }}

        assert_receive({:activate, {:ok, :get_user_orders}}, @timeout)
      end
    end

    test "returns errors if authentication fails", %{
      syndicates_with_strategy: syndicates_with_strategy,
      from: from,
      auth: auth,
      user: user
    } do
      with_mocks([
        {
          Store,
          [],
          [
            activate_syndicates: fn syndicates_to_activate ->
              assert syndicates_to_activate == syndicates_with_strategy
              {:error, :enoent}
            end
          ]
        },
        {
          AuctionHouse,
          [],
          [
            get_saved_login: fn -> {:ok, {auth, user}} end
          ]
        }
      ]) do
        assert Activate.handle_continue(
                 nil,
                 %{
                   deps: %{store: Store, auction_house: AuctionHouse},
                   non_patreon_order_limit: 100,
                   args: %{syndicates_with_strategy: syndicates_with_strategy},
                   from: from
                 }
               ) ==
                 {
                   :stop,
                   {:error, :enoent},
                   %{
                     args: %{
                       syndicates_with_strategy: %{new_loka: :top_five_average, perrin_sequence: :top_three_average}
                     },
                     deps: %{store: Store, auction_house: AuctionHouse},
                     from: from,
                     non_patreon_order_limit: 100
                   }
                 }

        assert_receive({:activate, {:error, {:continue, {:error, :enoent}}}}, @timeout)
      end
    end
  end

  describe "handle_info {:get_user_orders, {:ok, placed_orders}}" do
    setup do
      syndicates_with_strategy = %{new_loka: :top_five_average, perrin_sequence: :top_three_average}
      from = self()
      user = %User{ingame_name: "username", patreon?: false}

      %{
        syndicates_with_strategy: syndicates_with_strategy,
        from: from,
        user: user,
        limit: 5
      }
    end

    test "sends :no_slots_free messages if there is no place for more orders", %{
      syndicates_with_strategy: syndicates_with_strategy,
      from: from,
      user: user,
      limit: limit
    } do
      with_mocks([
        {
          Store,
          [],
          [
            list_products: fn syndicate_ids ->
              expected_ids = Map.keys(syndicates_with_strategy)
              assert syndicate_ids == expected_ids
              {:ok, [Helpers.create_product(), Helpers.create_product(), Helpers.create_product()]}
            end
          ]
        }
      ]) do
        placed_orders = [
          Helpers.create_placed_order(),
          Helpers.create_placed_order(),
          Helpers.create_placed_order(),
          Helpers.create_placed_order(),
          Helpers.create_placed_order()
        ]

        assert Activate.handle_info(
                 {:get_user_orders, {:ok, placed_orders}},
                 %{
                   deps: %{store: Store, auction_house: AuctionHouse},
                   args: %{syndicates_with_strategy: syndicates_with_strategy},
                   non_patreon_order_limit: limit,
                   user: user,
                   from: from
                 }
               ) ==
                 {:stop, :normal,
                  %{
                    args: %{syndicates_with_strategy: syndicates_with_strategy},
                    user: user,
                    deps: %{store: Store, auction_house: AuctionHouse},
                    from: from,
                    non_patreon_order_limit: limit
                  }}

        assert_receive({:activate, {:ok, :no_slots_free}}, @timeout)
      end
    end

    test "requests orders for products of selected syndicates", %{
      syndicates_with_strategy: syndicates_with_strategy,
      from: from,
      user: user,
      limit: limit
    } do
      products =
        [
          Helpers.create_product(name: "Abating Link", price: 20),
          Helpers.create_product(name: "Vampire Leech", price: 17),
          Helpers.create_product(name: "Pool of Life", price: 14)
        ]

      with_mocks([
        {
          Store,
          [],
          [
            list_products: fn syndicate_ids ->
              expected_ids = Map.keys(syndicates_with_strategy)
              assert syndicate_ids == expected_ids
              {:ok, products}
            end
          ]
        },
        {
          AuctionHouse,
          [],
          [
            get_item_orders: fn product_name ->
              valid_names = Enum.map(products, & &1.name)
              assert product_name in valid_names
              :ok
            end
          ]
        }
      ]) do
        placed_orders = [
          Helpers.create_placed_order(),
          Helpers.create_placed_order(),
          Helpers.create_placed_order()
        ]

        assert Activate.handle_info(
                 {:get_user_orders, {:ok, placed_orders}},
                 %{
                   deps: %{store: Store, auction_house: AuctionHouse},
                   args: %{syndicates_with_strategy: syndicates_with_strategy},
                   non_patreon_order_limit: limit,
                   user: user,
                   from: from
                 }
               ) ==
                 {
                   :noreply,
                   %{
                     args: %{syndicates_with_strategy: syndicates_with_strategy},
                     user: user,
                     deps: %{store: Store, auction_house: AuctionHouse},
                     from: from,
                     non_patreon_order_limit: limit,
                     order_number_limit: 2,
                     product_prices: %{
                       %Product{
                         rank: "n/a",
                         quantity: 1,
                         default_price: 16,
                         min_price: 15,
                         id: "default_id",
                         name: "Abating Link"
                       } => nil,
                       %Product{
                         rank: "n/a",
                         quantity: 1,
                         default_price: 16,
                         min_price: 15,
                         id: "default_id",
                         name: "Pool of Life"
                       } => nil,
                       %Product{
                         rank: "n/a",
                         quantity: 1,
                         default_price: 16,
                         min_price: 15,
                         id: "default_id",
                         name: "Vampire Leech"
                       } => nil
                     },
                     total_products_count: 3
                   }
                 }

        assert_receive({:activate, {:ok, :calculating_item_prices}}, @timeout)
      end
    end

    test "Notifies client of error if it fails to fetch products", %{
      syndicates_with_strategy: syndicates_with_strategy,
      from: from,
      user: user,
      limit: limit
    } do
      with_mocks([
        {
          Store,
          [],
          [
            list_products: fn _syndicate_ids ->
              {:error, :enoent}
            end
          ]
        }
      ]) do
        placed_orders = [
          Helpers.create_placed_order(),
          Helpers.create_placed_order(),
          Helpers.create_placed_order()
        ]

        assert Activate.handle_info(
                 {:get_user_orders, {:ok, placed_orders}},
                 %{
                   deps: %{store: Store, auction_house: AuctionHouse},
                   args: %{syndicates_with_strategy: syndicates_with_strategy},
                   non_patreon_order_limit: limit,
                   user: user,
                   from: from
                 }
               ) ==
                 {
                   :stop,
                   {:error, :enoent},
                   %{
                     args: %{syndicates_with_strategy: syndicates_with_strategy},
                     user: user,
                     deps: %{store: Store, auction_house: AuctionHouse},
                     from: from,
                     non_patreon_order_limit: 5
                   }
                 }

        assert_receive({:activate, {:error, {:get_item_orders, {:error, :enoent}}}}, @timeout)
      end
    end
  end
end
