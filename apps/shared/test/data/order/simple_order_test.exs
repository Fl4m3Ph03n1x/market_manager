defmodule Shared.Data.Order.SimpleOrderTest do
  @moduledoc false

  use ExUnit.Case

  alias Jason
  alias Shared.Data.Order.SimpleOrder

  test "new/1 returns correct SimpleOrderTest" do
    data = %{
      "item_id" => "5962ff05d3ffb64d46e3c47f",
      "order_type" => "sell",
      "platinum" => 15,
      "quantity" => 1
    }

    assert SimpleOrder.new(data) == %SimpleOrder{
             item_id: "5962ff05d3ffb64d46e3c47f",
             order_type: "sell",
             platinum: 15,
             quantity: 1
           }
  end

  test "converts to JSON correctly" do
    order = %SimpleOrder{
      item_id: "5962ff05d3ffb64d46e3c47f",
      order_type: "sell",
      platinum: 15,
      quantity: 1
    }

    json = Jason.encode!(order)

    assert Jason.decode!(json) == %{
             "type" => "sell",
             "visible" => true,
             "platinum" => 15,
             "quantity" => 1,
             "itemId" => "5962ff05d3ffb64d46e3c47f"
           }
  end
end
