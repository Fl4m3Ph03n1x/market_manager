ExUnit.start()

defmodule Helpers do
  @moduledoc false

  alias Shared.Data.{Order, OrderInfo, Product}
  alias Shared.Utils.Maps

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

  @default_order_info %{
    "visible" => true,
    "user" => %{"status" => "ingame"},
    "platform" => "pc",
    "order_type" => "sell",
    "platinum" => 15
  }

  @spec create_order(Keyword.t()) :: Order.t()
  def create_order(data) when is_list(data),
    do:
      @default_order
      |> Map.merge(Maps.to_string_map(data))
      |> Order.new()

  @spec create_product(Keyword.t()) :: Product.t()
  def create_product(data) when is_list(data),
    do:
      @default_product
      |> Map.merge(Maps.to_string_map(data))
      |> Product.new()

  @spec create_order_info(Keyword.t()) :: Product.t()
  def create_order_info(data) when is_list(data),
    do:
      @default_order_info
      |> Map.merge(Maps.to_string_map(data))
      |> OrderInfo.new()
end
