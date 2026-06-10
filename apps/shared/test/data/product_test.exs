defmodule Shared.Data.ProductTest do
  @moduledoc false

  use ExUnit.Case, async: true

  alias Shared.Data.Product
  alias Shared.Data.Product.{Arcane, Mod, ModWithoutRank}

  test "new/1 returns a Product" do
    # mod
    assert Product.new(%{
             "name" => "Eroding Blight",
             "id" => "54a74454e779892d5e5155a0",
             "min_price" => 14,
             "default_price" => 16,
             "type" => "mod"
           }) == %Mod{
             name: "Eroding Blight",
             id: "54a74454e779892d5e5155a0",
             min_price: 14,
             default_price: 16
           }

    # mod with atagraph art
    assert Product.new(%{
             "name" => "Galvanized Hell",
             "id" => "60e5b8fb4794450053e9993d",
             "min_price" => 14,
             "default_price" => 16,
             "type" => "mod",
             "subtype" => "regular"
           }) == %Mod{
             name: "Galvanized Hell",
             id: "60e5b8fb4794450053e9993d",
             min_price: 14,
             default_price: 16,
             subtype: "regular"
           }

    # mod_without_rank
    assert Product.new(%{
             "name" => "Astral Autopsy",
             "id" => "588a789c3cf52c408a2f88dc",
             "min_price" => 50,
             "default_price" => 60,
             "type" => "mod_without_rank"
           }) == %ModWithoutRank{
             name: "Astral Autopsy",
             id: "588a789c3cf52c408a2f88dc",
             min_price: 50,
             default_price: 60
           }

    # Arcanes
    assert Product.new(%{
             "name" => "Molt Vigor",
             "id" => "626a1978f40db600660a1d7b",
             "min_price" => 2,
             "default_price" => 3,
             "quantity" => 26,
             "type" => "arcane"
           }) == %Arcane{
             name: "Molt Vigor",
             id: "626a1978f40db600660a1d7b",
             min_price: 2,
             default_price: 3,
             quantity: 26
           }
  end
end
