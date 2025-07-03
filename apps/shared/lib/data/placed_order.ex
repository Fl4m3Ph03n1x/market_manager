defmodule Shared.Data.PlacedOrder do
  @moduledoc """
  Represents an order that was placed by the User of this application. I could
  have used OrderInfo as well, but since the later one has a ton of information
  I don't really need/want to deal with, I opted for this instead.
  """

  use TypedStruct

  alias Shared.Utils.Structs

  @type order_id :: String.t()
  @type item_id :: String.t()

  @type placed_order ::
          %{
            (order_id :: String.t()) => String.t(),
            (item_id :: String.t()) => String.t()
          }
          | [order_id: String.t(), item_id: String.t()]

  @derive Jason.Encoder
  typedstruct enforce: true do
    @typedoc "A PlacedOrder"

    field(:order_id, order_id())
    field(:item_id, item_id())
  end

  @spec new(placed_order()) :: __MODULE__.t()
  def new(
        %{
          "order_id" => order_id,
          "item_id" => item_id
        } = placed_order
      )
      when is_binary(order_id) and is_binary(item_id),
      do: Structs.string_map_to_struct(placed_order, __MODULE__)

  @spec new(placed_order()) :: __MODULE__.t()
  def new([order_id: order_id, item_id: item_id] = placed_order)
      when is_binary(order_id) and is_binary(item_id),
      do: struct(__MODULE__, placed_order)
end
