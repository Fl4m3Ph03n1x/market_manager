defmodule Shared.Data.Product.ModWithoutRankTest do
  @moduledoc false

  use ExUnit.Case, async: true

  alias Jason
  alias Shared.Data.Product.ModWithoutRank

  test "new/1 returns correct ModWithoutRank" do
    assert ModWithoutRank.new(%{
             "name" => "Astral Autopsy",
             "id" => "588a789c3cf52c408a2f88dc",
             "min_price" => 50,
             "default_price" => 60
           }) == %ModWithoutRank{
             name: "Astral Autopsy",
             id: "588a789c3cf52c408a2f88dc",
             min_price: 50,
             default_price: 60
           }
  end

  test "to_sell_order!/2 converts to JSON correctly" do
    mod = %ModWithoutRank{
      name: "Astral Autopsy",
      id: "588a789c3cf52c408a2f88dc",
      min_price: 50,
      default_price: 60
    }

    sell_price = 100

    expected_sell_order =
      %{
        itemId: "588a789c3cf52c408a2f88dc",
        type: "sell",
        visible: true,
        platinum: 100,
        quantity: 1
      }

    assert ModWithoutRank.to_sell_order!(mod, sell_price) == expected_sell_order
  end
end
