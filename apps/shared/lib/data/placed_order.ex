defmodule Shared.Data.PlacedOrder do
  @moduledoc """
  Represents an order that was placed by the user of market manager.
  """

  use TypedStruct

  alias Shared.Utils.Structs

  @type placed_order :: %{
          (order_id :: String.t()) => String.t(),
          (item_id :: String.t()) => String.t()
        }

  @derive Jason.Encoder
  typedstruct enforce: true do
    @typedoc "A PlacedOrder"

    field(:order_id, String.t())
    field(:item_id, String.t())
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
end
