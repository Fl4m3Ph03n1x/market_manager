defmodule Shared.Data.Order.SimpleOrder do
  @moduledoc """
  Represents an order to be made to warframe market without a rank.
  """

  use TypedStruct

  import Shared.Utils.ExtraGuards

  alias Shared.Utils.Structs

  @type item_id :: String.t()
  @type order_type :: String.t()
  @type platinum :: pos_integer()
  @type quantity :: pos_integer()

  @type simple_order :: %{
          (item_id :: String.t()) => String.t(),
          (order_type :: String.t()) => String.t(),
          (platinum :: String.t()) => pos_integer(),
          (quantity :: String.t()) => pos_integer()
        }

  typedstruct enforce: true do
    @typedoc "An order."

    field(:item_id, item_id())
    field(:order_type, order_type())
    field(:platinum, platinum())
    field(:quantity, quantity())
  end

  @spec new(simple_order) :: __MODULE__.t()
  def new(
        %{
          "item_id" => item_id,
          "order_type" => order_type,
          "platinum" => platinum,
          "quantity" => quantity
        } = order
      )
      when is_binary(order_type) and is_binary(item_id) and
             is_pos_integer(platinum) and is_pos_integer(quantity),
      do: Structs.string_map_to_struct(order, __MODULE__)

  defimpl Jason.Encoder, for: __MODULE__ do
    def encode(order, opts) do
      data =
        %{
          itemId: order.item_id,
          type: order.order_type,
          visible: true,
          platinum: order.platinum,
          quantity: order.quantity
        }

      Jason.Encode.map(data, opts)
    end
  end
end
