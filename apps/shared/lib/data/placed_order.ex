defmodule Shared.Data.PlacedOrder do
  @moduledoc """
  Represents an order that was placed by the user of market manager.
  """

  use TypedStruct

  alias Shared.Utils.Structs

  @type placed_order :: %{
          (order_id :: String.t()) => String.t(),
          (item_name :: String.t()) => String.t()
        }

  @derive Jason.Encoder
  typedstruct enforce: true do
    @typedoc "A PlacedOrder"

    field(:order_id, String.t())
    field(:item_name, String.t())
  end

  @spec new(placed_order()) :: __MODULE__.t()
  def new(
        %{
          "order_id" => order_id,
          "item_name" => item_name
        } = placed_order
      )
      when is_binary(order_id) and is_binary(item_name),
      do: Structs.string_map_to_struct(placed_order, __MODULE__)
end
