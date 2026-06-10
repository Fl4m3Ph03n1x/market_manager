defmodule Shared.Data.Product.ModTest do
  @moduledoc false

  use ExUnit.Case, async: true

  alias Jason
  alias Shared.Data.Product.Mod

  test "new/1 returns a regular Mod" do
    assert Mod.new(%{
             "name" => "Pilfering Strangledome",
             "id" => "5cb04868fc2db2068006980e",
             "min_price" => 14,
             "default_price" => 16
           }) == %Mod{
             name: "Pilfering Strangledome",
             id: "5cb04868fc2db2068006980e",
             min_price: 14,
             default_price: 16
           }
  end

  test "new/1 returns an atagraph Mod" do
    assert Mod.new(%{
             "name" => "Parasitic Vitality",
             "id" => "6604a680dbdd5c1673781dbb",
             "min_price" => 14,
             "default_price" => 16,
             "subtype" => "regular"
           }) == %Mod{
             name: "Parasitic Vitality",
             id: "6604a680dbdd5c1673781dbb",
             min_price: 14,
             default_price: 16,
             subtype: "regular"
           }
  end

  test "to_sell_order!/2 converts atagraph mod to JSON correctly" do
    atagraph_mod = %Mod{
      name: "Parasitic Vitality",
      id: "6604a680dbdd5c1673781dbb",
      min_price: 14,
      default_price: 16,
      subtype: "atagraph"
    }

    sell_price = 15

    expected_sell_order =
      %{
        type: "sell",
        visible: true,
        platinum: 15,
        rank: 0,
        quantity: 1,
        itemId: "6604a680dbdd5c1673781dbb",
        subtype: "atagraph"
      }

    assert Mod.to_sell_order!(atagraph_mod, sell_price) == expected_sell_order
  end

  test "to_sell_order!/2 converts regular mod to JSON correctly" do
    regular_mod = %Mod{
      name: "Pilfering Strangledome",
      id: "5cb04868fc2db2068006980e",
      min_price: 14,
      default_price: 16
    }

    sell_price = 15

    expected_sell_order =
      %{
        type: "sell",
        visible: true,
        platinum: 15,
        rank: 0,
        quantity: 1,
        itemId: "5cb04868fc2db2068006980e"
      }

    assert Mod.to_sell_order!(regular_mod, sell_price) == expected_sell_order
  end
end
