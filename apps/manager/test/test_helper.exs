ExUnit.start()

defmodule Helpers do
  @moduledoc false

  alias Shared.Data.{Order, Product}

  @default_order %{
    "item_id" => "default_item_id",
    "platinum" => 15,
    "quantity" => 1,
    "order_type" => "sell"
  }

  @default_product %{
    "name" => "default_name",
    "id" => "default_id",
    "min_price" => 15,
    "default_price" => 16,
    "rank" => "n/a",
    "quantity" => 1
  }

  @spec create_order(Keyword.t()) :: Order.t()
  def create_order(data) when is_list(data),
    do:
      @default_order
      |> Map.merge(Map.new(data, fn {k, v} -> {Atom.to_string(k), v} end))
      |> Order.new()

  @spec create_product(Keyword.t()) :: Product.t()
  def create_product(data) when is_list(data),
    do:
      @default_product
      |> Map.merge(Map.new(data, fn {k, v} -> {Atom.to_string(k), v} end))
      |> Product.new()
end
