defmodule Shared.Data.Order.ArcaneOrderTest do
  @moduledoc false

  use ExUnit.Case

  alias Jason
  alias Shared.Data.Order.ArcaneOrder

  test "new/1 returns correct ArcaneOrder" do
    data = %{
      "item_id" => "5962ff05d3ffb64d46e3c47f",
      "order_type" => "sell",
      "platinum" => 15,
      "quantity" => 21,
      "per_trade" => 1
    }

    assert ArcaneOrder.new(data) == %ArcaneOrder{
             item_id: "5962ff05d3ffb64d46e3c47f",
             order_type: "sell",
             platinum: 15,
             quantity: 21,
             per_trade: 1
           }
  end

  test "converts to JSON correctly" do
    order = %ArcaneOrder{
      item_id: "5962ff05d3ffb64d46e3c47f",
      order_type: "sell",
      platinum: 15,
      quantity: 21,
      per_trade: 1
    }

    json = Jason.encode!(order)

    assert Jason.decode!(json) == %{
             "type" => "sell",
             "visible" => true,
             "platinum" => 15,
             "quantity" => 21,
             "itemId" => "5962ff05d3ffb64d46e3c47f",
             "perTrade" => 1,
             "rank" => 0
           }
  end
end
