defmodule Shared.Data.OrderTest do
  @moduledoc false

  use ExUnit.Case

  alias Shared.Data.Order
  alias Shared.Data.Order.{RankedOrder, SimpleOrder}

  test "new/1 returns a SimpleOrder" do
    assert Order.new(%{
             "item_id" => "54e0c9eee7798903744178aa",
             "order_type" => "sell",
             "platinum" => 14,
             "quantity" => 1
           }) == %SimpleOrder{
             item_id: "54e0c9eee7798903744178aa",
             order_type: "sell",
             platinum: 14,
             quantity: 1
           }

    assert Order.new(%{
             "item_id" => "54e0c9eee7798903744178aa",
             "order_type" => "sell",
             "platinum" => 14,
             "quantity" => 1,
             "mod_rank" => 0
           }) == %RankedOrder{
             item_id: "54e0c9eee7798903744178aa",
             order_type: "sell",
             platinum: 14,
             quantity: 1,
             mod_rank: 0
           }
  end
end
