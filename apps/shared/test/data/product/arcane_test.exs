defmodule Shared.Data.Product.ArcaneTest do
  @moduledoc false

  use ExUnit.Case, async: true

  alias Jason
  alias Shared.Data.Product.Arcane

  test "new/1 returns an Arcane" do
    assert Arcane.new(%{
             "name" => "Magus Nourish",
             "id" => "5a0475096c4655012038ddc4",
             "min_price" => 2,
             "default_price" => 5,
             "quantity" => 13
           }) == %Arcane{
             name: "Magus Nourish",
             id: "5a0475096c4655012038ddc4",
             min_price: 2,
             default_price: 5,
             quantity: 13
           }
  end

  test "to_sell_order!/2 converts to JSON correctly" do
    arcane = %Arcane{
      name: "Magus Nourish",
      id: "5a0475096c4655012038ddc4",
      min_price: 2,
      default_price: 5,
      quantity: 13
    }

    sell_price = 10

    expected_sell_order = %{
      type: "sell",
      visible: true,
      platinum: 10,
      rank: 0,
      quantity: 13,
      itemId: "5a0475096c4655012038ddc4",
      perTrade: 1
    }

    assert Arcane.to_sell_order!(arcane, sell_price) == expected_sell_order
  end
end
