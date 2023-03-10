defmodule Shared.Data.Order.RankedOrder do
  @moduledoc """
  Represents an order to be made to warframe market.
  """

  use TypedStruct

  import Shared.Utils.ExtraGuards

  alias Shared.Utils.Structs

  @type ranked_order ::
          %{
            (item_id :: String.t()) => String.t(),
            (order_type :: String.t()) => String.t(),
            (platinum :: String.t()) => pos_integer(),
            (quantity :: String.t()) => pos_integer(),
            (mod_rank :: String.t()) => non_neg_integer
          }

  @derive Jason.Encoder
  typedstruct enforce: true do
    @typedoc "An order."

    field(:item_id, String.t())
    field(:order_type, String.t())
    field(:platinum, pos_integer())
    field(:quantity, pos_integer())
    field(:mod_rank, non_neg_integer())
  end

  @spec new(ranked_order) :: __MODULE__.t()
  def new(
        %{
          "item_id" => item_id,
          "order_type" => order_type,
          "platinum" => platinum,
          "quantity" => quantity,
          "mod_rank" => mod_rank
        } = order
      )
      when is_binary(order_type) and is_binary(item_id) and is_pos_integer(platinum) and
             is_pos_integer(quantity) and is_non_neg_integer(mod_rank),
      do: Structs.string_map_to_struct(order, __MODULE__)
end
