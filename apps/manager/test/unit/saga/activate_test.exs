defmodule Manager.Saga.ActivateTest do
  @moduledoc false

  use ExUnit.Case

  import Mock

  alias AuctionHouse
  alias Helpers
  alias Manager.Saga.Activate

  alias Shared.Data.{Authorization, PlacedOrder, User}
  alias Shared.Data.Product.{Arcane, Mod, ModWithoutRank}

  alias Store

  @timeout 5000

  describe "handle_continue/2" do
    setup do
      syndicates_with_strategy = %{new_loka: :top_five_average, perrin_sequence: :top_three_average}
      from = self()
      authorization = %Authorization{access_token: "a_token"}
      user = %User{ingame_name: "Username", slug: "username", patreon?: false}

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
              assert a_user == user.slug
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
      user = %User{ingame_name: "Username", slug: "username", patreon?: false}

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
            end,
            deactivate_syndicates: fn syndicate_ids ->
              expected_ids = Map.keys(syndicates_with_strategy)
              assert syndicate_ids == expected_ids
              :ok
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

    test "sends :failed_rollback_activation messages if there is no place for more orders and activation rollback fails",
         %{
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
            end,
            deactivate_syndicates: fn _syndicate_ids ->
              {:error, :enoent}
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
                 {:stop, {:error, :enoent},
                  %{
                    args: %{syndicates_with_strategy: syndicates_with_strategy},
                    user: user,
                    deps: %{store: Store, auction_house: AuctionHouse},
                    from: from,
                    non_patreon_order_limit: limit
                  }}

        assert_receive({:activate, {:error, {:failed_rollback_activation, _}}}, @timeout)
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
          Helpers.create_product(name: "Astral Autopsy", price: 20, type: "mod_without_rank"),
          Helpers.create_product(name: "Molt Vigor", price: 17, type: "arcane", per_trade: 1, quantity: 10),
          Helpers.create_product(name: "Pool of Life", price: 14, type: "mod")
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
                       %ModWithoutRank{
                         default_price: 16,
                         min_price: 15,
                         id: "default_id",
                         name: "Astral Autopsy"
                       } => nil,
                       %Mod{
                         default_price: 16,
                         min_price: 15,
                         id: "default_id",
                         name: "Pool of Life"
                       } => nil,
                       %Arcane{
                         quantity: 10,
                         default_price: 16,
                         min_price: 15,
                         id: "default_id",
                         name: "Molt Vigor"
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

  describe "handle_info {:place_order, {:error, {:unauthorized, item_id}}}" do
    test "stops normally, reports the expired session and keeps the syndicates active" do
      state = %{
        deps: %{store: Store, auction_house: AuctionHouse},
        args: %{syndicates_with_strategy: %{new_loka: :top_five_average}},
        from: self()
      }

      with_mock Store, deactivate_syndicates: fn _syndicate_ids -> :ok end do
        assert Activate.handle_info({:place_order, {:error, {:unauthorized, "54a74454e779892d5e5155c5"}}}, state) ==
                 {:stop, :normal, state}

        assert_received({:activate, {:error, :unauthorized}})
        assert_not_called(Store.deactivate_syndicates(:_))
      end
    end
  end

  describe "handle_info {:place_order, {:error, {reason, item_id}}}" do
    test "records the failed order and keeps waiting for the pending ones" do
      savage_silence = %Mod{id: "54a74455e779892d5e515690", name: "Savage Silence", min_price: 14, default_price: 16}
      pool_of_life = %Mod{id: "54a74454e779892d5e51564c", name: "Pool of Life", min_price: 14, default_price: 16}
      error = {:error, {:bad_request, "54a74455e779892d5e515690"}}

      state = %{
        from: self(),
        orders_placed: %{{savage_silence, 16} => nil, {pool_of_life, 22} => nil}
      }

      assert Activate.handle_info({:place_order, error}, state) ==
               {:noreply, %{state | orders_placed: %{{savage_silence, 16} => error, {pool_of_life, 22} => nil}}}

      assert_received({:activate, {:error, {:place_order, {:error, {:bad_request, "54a74455e779892d5e515690"}}}}})
      refute_received({:activate, {:ok, :done}})
    end

    test "finishes the activation when the last pending order fails" do
      savage_silence = %Mod{id: "54a74455e779892d5e515690", name: "Savage Silence", min_price: 14, default_price: 16}
      pool_of_life = %Mod{id: "54a74454e779892d5e51564c", name: "Pool of Life", min_price: 14, default_price: 16}
      pool_of_life_order = %PlacedOrder{item_id: "54a74454e779892d5e51564c", order_id: "66b9c7aa6b17410a57974e4b"}
      error = {:error, {:bad_request, "54a74455e779892d5e515690"}}

      state = %{
        from: self(),
        orders_placed: %{{savage_silence, 16} => nil, {pool_of_life, 22} => pool_of_life_order}
      }

      assert Activate.handle_info({:place_order, error}, state) ==
               {:stop, :normal,
                %{state | orders_placed: %{{savage_silence, 16} => error, {pool_of_life, 22} => pool_of_life_order}}}

      assert_received({:activate, {:error, {:place_order, {:error, {:bad_request, "54a74455e779892d5e515690"}}}}})
      assert_received({:activate, {:ok, :done}})
    end
  end

  describe "handle_info {:place_order, {:ok, placed_order}}" do
    test "counts a failed order in the progress and finishes the activation" do
      savage_silence = %Mod{id: "54a74455e779892d5e515690", name: "Savage Silence", min_price: 14, default_price: 16}
      pool_of_life = %Mod{id: "54a74454e779892d5e51564c", name: "Pool of Life", min_price: 14, default_price: 16}
      pool_of_life_order = %PlacedOrder{item_id: "54a74454e779892d5e51564c", order_id: "66b9c7aa6b17410a57974e4b"}
      error = {:error, {:bad_request, "54a74455e779892d5e515690"}}

      state = %{
        deps: %{store: Store, auction_house: AuctionHouse},
        args: %{syndicates_with_strategy: %{perrin_sequence: :top_five_average}},
        product_prices: %{savage_silence => 16, pool_of_life => 22},
        non_patreon_order_limit: 100,
        user: %User{ingame_name: "Username", slug: "username", patreon?: false},
        order_number_limit: 2,
        orders_placed: %{{savage_silence, 16} => error, {pool_of_life, 22} => nil},
        from: self()
      }

      assert Activate.handle_info({:place_order, {:ok, pool_of_life_order}}, state) ==
               {:stop, :normal,
                %{state | orders_placed: %{{savage_silence, 16} => error, {pool_of_life, 22} => pool_of_life_order}}}

      assert_received({:activate, {:ok, {:order_placed, "Pool of Life", 2, 2}}})
      assert_received({:activate, {:ok, :done}})
    end
  end
end
