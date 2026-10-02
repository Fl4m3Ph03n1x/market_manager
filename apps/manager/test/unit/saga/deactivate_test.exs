defmodule Manager.Saga.DeactivateTest do
  @moduledoc false

  use ExUnit.Case

  import Mock

  alias AuctionHouse
  alias Helpers
  alias Manager.Saga.Deactivate
  alias Shared.Data.User
  alias Store

  setup do
    user = %User{ingame_name: "Username", slug: "username", patreon?: false}

    state = %{
      deps: %{store: Store, auction_house: AuctionHouse},
      args: %{syndicate_ids: [:new_loka]},
      user: user,
      from: self()
    }

    {:ok, state: state}
  end

  describe "handle_info/2 get_user_orders success" do
    @tag :capture_log
    test "completes after one delete fails and the remaining delete succeeds", %{state: state} do
      failed_order = Helpers.create_placed_order(order_id: "failed-order", item_id: "failed-product")
      deleted_order = Helpers.create_placed_order(order_id: "deleted-order", item_id: "deleted-product")
      failed_product = Helpers.create_product(id: failed_order.item_id, name: "Failed Product")
      deleted_product = Helpers.create_product(id: deleted_order.item_id, name: "Deleted Product")

      with_mocks([
        {
          Store,
          [],
          [
            list_active_syndicates: [
              in_series([], [{:ok, %{new_loka: :top_three_average}}, {:ok, %{}}])
            ],
            list_products: fn _syndicate_ids -> {:ok, [failed_product, deleted_product]} end,
            get_product_by_id: fn _product_id -> {:ok, deleted_product} end,
            deactivate_syndicates: fn _syndicate_ids -> :ok end
          ]
        },
        {AuctionHouse, [], [delete_order: fn _order -> :ok end]}
      ]) do
        assert {:noreply, deleting_state} =
                 Deactivate.handle_info(
                   {:get_user_orders, {:ok, [failed_order, deleted_order]}},
                   state
                 )

        assert_receive {:deactivate, {:ok, :deleting_orders}}

        assert {:noreply, failed_state} =
                 Deactivate.handle_info(
                   {:delete_order, {:error, :server_error}},
                   deleting_state
                 )

        assert_receive {:deactivate, {:error, {:delete_order, {:error, :server_error}}}}

        assert {:stop, :normal, _state} =
                 Deactivate.handle_info({:delete_order, {:ok, deleted_order}}, failed_state)

        assert_receive {:deactivate, {:ok, {:order_deleted, "Deleted Product", 2, 2}}}
        assert_receive {:deactivate, {:ok, :done}}
        assert_called(AuctionHouse.delete_order(failed_order))
        assert_called(AuctionHouse.delete_order(deleted_order))
        assert_called_exactly(Store.list_active_syndicates(), 2)
        assert_called_exactly(Store.list_products([:new_loka]), 1)
        assert_called_exactly(Store.get_product_by_id(deleted_product.id), 1)
        assert_called_exactly(Store.deactivate_syndicates(state.args.syndicate_ids), 1)
      end
    end
  end

  describe "handle_info/2 delete_order unauthorized" do
    test "stops normally, reports the expired session and keeps the syndicates active", %{state: state} do
      with_mock Store, deactivate_syndicates: fn _syndicate_ids -> :ok end do
        assert Deactivate.handle_info({:delete_order, {:error, :unauthorized}}, state) == {:stop, :normal, state}
        assert_received({:deactivate, {:error, :unauthorized}})
        assert_not_called(Store.deactivate_syndicates(:_))
      end
    end
  end
end
