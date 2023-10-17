defmodule Shared.Data.ProductTest do
  @moduledoc false

  use ExUnit.Case

  alias Shared.Data.Product

  test "new/1 returns a Product" do
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

    assert Product.new(%{
             "name" => "Eroding Blight",
             "id" => "54a74454e779892d5e5155a0",
             "min_price" => 14,
             "default_price" => 16,
             "quantity" => 2,
             "rank" => 1
           }) == %Product{
             name: "Eroding Blight",
             id: "54a74454e779892d5e5155a0",
             min_price: 14,
             default_price: 16,
             quantity: 1,
             rank: 1
           }

    assert Product.new(
             name: "Eroding Blight",
             id: "54a74454e779892d5e5155a0",
             min_price: 14,
             default_price: 16
           ) == %Product{
             name: "Eroding Blight",
             id: "54a74454e779892d5e5155a0",
             min_price: 14,
             default_price: 16,
             quantity: 1,
             rank: 0
           }
  end
end
