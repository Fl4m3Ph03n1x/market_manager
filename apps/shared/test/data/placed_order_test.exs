defmodule Shared.Data.PlacedOrderTest do
  @moduledoc false

  use ExUnit.Case

  alias Shared.Data.PlacedOrder

  test "new/1 returns a PlacedOrder" do
    assert PlacedOrder.new(%{
             "order_id" => "5911f11d97a0add8e9d5da3e",
             "item_id" => "54e0c9eee7798903744178aa"
           }) == %PlacedOrder{
             order_id: "5911f11d97a0add8e9d5da3e",
             item_id: "54e0c9eee7798903744178aa"
           }

    assert PlacedOrder.new(
             order_id: "5911f11d97a0add8e9d5da3e",
             item_id: "54e0c9eee7798903744178aa"
           ) == %PlacedOrder{
             order_id: "5911f11d97a0add8e9d5da3e",
             item_id: "54e0c9eee7798903744178aa"
           }
  end
end
