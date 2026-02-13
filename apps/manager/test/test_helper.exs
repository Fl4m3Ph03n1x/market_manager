ExUnit.start()

defmodule Helpers do
  @moduledoc false

  alias Shared.Data.{Order, OrderInfo, PlacedOrder, Product, Strategy}
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
    "user" => %{
      "platform" => "pc",
      "status" => "ingame",
      "ingameName" => "some_user",
      "slug" => "some_user",
      "crossplay" => false
    },
    "type" => "sell",
    "platinum" => 15
  }

  @default_placed_order %{
    "item_id" => "default_item_id",
    "order_id" => "default_order_id"
  }

  @spec create_order(Keyword.t()) :: Order.t()
  def create_order(data) when is_list(data),
    do:
      @default_order
      |> Map.merge(Maps.to_string_map(data))
      |> Order.new()

  @spec create_product :: Product.t()
  def create_product, do: create_product([])

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

  @spec create_placed_order :: PlacedOrder.t()
  def create_placed_order, do: create_placed_order([])

  @spec create_placed_order(Keyword.t()) :: PlacedOrder.t()
  def create_placed_order(data) when is_list(data),
    do:
      @default_placed_order
      |> Map.merge(Maps.to_string_map(data))
      |> PlacedOrder.new()

  @spec strategy(atom) :: Strategy.t()
  def strategy(:top_three_average),
    do:
      Strategy.new(
        name: "Top 3 Average",
        id: :top_three_average,
        description: "Gets the 3 lowest prices for the given item and calculates the average."
      )

  def strategy(:top_five_average),
    do:
      Strategy.new(
        name: "Top 5 Average",
        id: :top_five_average,
        description: "Gets the 5 lowest prices for the given item and calculates the average."
      )

  def strategy(:equal_to_lowest),
    do:
      Strategy.new(
        name: "Equal to lowest",
        id: :equal_to_lowest,
        description: "Gets the lowest price for the given item and uses it."
      )

  def strategy(:lowest_minus_one),
    do:
      Strategy.new(
        name: "Lowest minus one",
        id: :lowest_minus_one,
        description: "Gets the lowest price for the given item and beats it by 1."
      )
end
