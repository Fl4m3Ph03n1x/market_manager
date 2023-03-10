ExUnit.start()

defmodule Helpers do
  @moduledoc false

  alias Manager.Type
  alias Shared.Data.{Order, Product}

  @spec create_order(Type.item_id(), platinum :: pos_integer) :: Order.t()
  def create_order(item_id, platinum),
    do:
      Order.new(%{
        "order_type" => "sell",
        "item_id" => item_id,
        "platinum" => platinum,
        "quantity" => 1
      })

  @spec create_order(Type.item_id(), platinum :: pos_integer, rank :: non_neg_integer) ::
          Order.t()
  def create_order(item_id, platinum, rank),
    do:
      Order.new(%{
        "order_type" => "sell",
        "item_id" => item_id,
        "platinum" => platinum,
        "quantity" => 1,
        "mod_rank" => rank
      })

  @spec create_product(name :: String.t(), Type.item_id()) :: Product.t()
  def create_product(name, id),
    do:
      Product.new(%{
        "name" => name,
        "id" => id,
        "min_price" => 15,
        "default_price" => 16,
        "rank" => "n/a",
        "quantity" => 1
      })

  @spec create_product(name :: String.t(), Type.item_id(), rank :: non_neg_integer) :: Product.t()
  def create_product(name, id, rank),
    do:
      Product.new(%{
        "name" => name,
        "id" => id,
        "min_price" => 15,
        "default_price" => 16,
        "rank" => rank,
        "quantity" => 1
      })
end
