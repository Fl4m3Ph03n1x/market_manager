defmodule Shared.Data.Order.RankedOrderTest do
  @moduledoc false

  use ExUnit.Case

  alias Jason
  alias Shared.Data.Order.RankedOrder

  test "new/1 returns correct RankedOrder" do
    data = %{
      "item_id" => "5962ff05d3ffb64d46e3c47f",
      "order_type" => "sell",
      "platinum" => 15,
      "quantity" => 1,
      "mod_rank" => 0
    }

    assert RankedOrder.new(data) == %RankedOrder{
             item_id: "5962ff05d3ffb64d46e3c47f",
             order_type: "sell",
             platinum: 15,
             quantity: 1,
             mod_rank: 0
           }
  end

  test "converts to JSON correctly" do
    order = %RankedOrder{
      item_id: "5962ff05d3ffb64d46e3c47f",
      order_type: "sell",
      platinum: 15,
      quantity: 1,
      mod_rank: 0
    }

    json = Jason.encode!(order)

    assert Jason.decode!(json) == %{
             "type" => "sell",
             "visible" => true,
             "platinum" => 15,
             "quantity" => 1,
             "itemId" => "5962ff05d3ffb64d46e3c47f",
             "rank" => 0
           }
  end
end
