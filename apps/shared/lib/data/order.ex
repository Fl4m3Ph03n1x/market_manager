defmodule Shared.Data.Order do
  @moduledoc """
  Represents an order to be made to warframe market. There are two types of
  orders thus far, RankedOrders and SimpleOrders. See respective files for more
  information.
  """

  alias __MODULE__.{RankedOrder, SimpleOrder}

  @type order :: RankedOrder.ranked_order() | SimpleOrder.simple_order()
  @type t ::  SimpleOrder.t() | RankedOrder.t()

  @spec new(order) :: t()
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
