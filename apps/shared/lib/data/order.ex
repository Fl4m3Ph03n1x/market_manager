defmodule Shared.Data.Order do
  @moduledoc """
  Represents an order to be made to warframe market.
  """

  alias __MODULE__.{RankedOrder, SimpleOrder}

  @type t :: RankedOrder.ranked_order() | SimpleOrder.simple_order()

  @spec new(t) :: SimpleOrder.t() | RankedOrder.t()
  def new(
        %{
          "item_id" => _item_id,
          "order_type" => _order_type,
          "platinum" => _platinum,
          "quantity" => _quantity,
          "mod_rank" => _mod_rank
        } = order
      ),
      do: RankedOrder.new(order)

  def new(
        %{
          "item_id" => _item_id,
          "order_type" => _order_type,
          "platinum" => _platinum,
          "quantity" => _quantity
        } = order
      ),
      do: SimpleOrder.new(order)
end
