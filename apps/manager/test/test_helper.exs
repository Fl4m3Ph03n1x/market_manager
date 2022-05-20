ExUnit.start()

defmodule Helpers do
  def create_order(item_id, platinum),
    do: %{
      "order_type" => "sell",
      "item_id" => item_id,
      "platinum" => platinum,
      "quantity" => 1
    }

  def create_order(item_id, platinum, rank),
    do: %{
      "order_type" => "sell",
      "item_id" => item_id,
      "platinum" => platinum,
      "quantity" => 1,
      "mod_rank" => rank
    }

  def create_product(name, id),
    do: %{
      "name" => name,
      "id" => id,
      "min_price" => 15,
      "default_price" => 16
    }

  def create_product(name, id, rank),
    do: %{
      "name" => name,
      "id" => id,
      "min_price" => 15,
      "default_price" => 16,
      "rank" => rank
    }
end
