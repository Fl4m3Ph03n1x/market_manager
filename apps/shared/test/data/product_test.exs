defmodule Shared.Data.ProductTest do
  @moduledoc false

  use ExUnit.Case

  alias Shared.Data.Product

  test "new/1 returns a Product" do
    # mod
    assert Product.new(%{
             "name" => "Eroding Blight",
             "id" => "54a74454e779892d5e5155a0",
             "min_price" => 14,
             "default_price" => 16
           }) == %Product{
             name: "Eroding Blight",
             id: "54a74454e779892d5e5155a0",
             min_price: 14,
             default_price: 16,
             quantity: 1,
             rank: 0
           }

    # mod_without_rank
    assert Product.new(%{
             "name" => "Astral Autopsy",
             "id" => "588a789c3cf52c408a2f88dc",
             "min_price" => 50,
             "default_price" => 60,
             "rank" => "n/a"
           }) == %Product{
             name: "Astral Autopsy",
             id: "588a789c3cf52c408a2f88dc",
             min_price: 50,
             default_price: 60,
             quantity: 1,
             rank: "n/a"
           }

    # arcane
    assert Product.new(%{
             "name" => "Molt Vigor",
             "id" => "626a1978f40db600660a1d7b",
             "min_price" => 2,
             "default_price" => 3,
             "quantity" => 26
           }) == %Product{
             name: "Molt Vigor",
             id: "626a1978f40db600660a1d7b",
             min_price: 2,
             default_price: 3,
             quantity: 26,
             rank: 0
           }
  end
end
