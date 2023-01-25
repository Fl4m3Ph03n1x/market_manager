defmodule AuctionHouse.Data.Order do
  @moduledoc """
  Represents an order to be made to warframe market.
  """

  use TypedStruct
  import AuctionHouse.Shared.ExtraGuards

  alias AuctionHouse.Shared.Utils

  @type order :: %{
          (item_id :: String.t()) => String.t(),
          (mod_rank :: String.t()) => non_neg_integer | String.t(),
          (order_type :: String.t()) => String.t(),
          (platinum :: String.t()) => non_neg_integer(),
          (quantity :: String.t()) => pos_integer()
        }

  @derive Jason.Encoder
  typedstruct enforce: true do
    @typedoc "An order."

    field(:item_id, String.t())
    field(:mod_rank, non_neg_integer() | String.t())
    field(:order_type, String.t())
    field(:platinum, non_neg_integer())
    field(:quantity, pos_integer())
  end

  @spec new(order) :: {:ok, __MODULE__.t()} | {:error, any}
  def new(
        %{
          "order_type" => order_type,
          "item_id" => item_id,
          "platinum" => platinum,
          "quantity" => quantity,
          "mod_rank" => mod_rank
        } = order
      )
      when is_binary(order_type) and is_binary(item_id) and
             is_non_neg_integer(platinum) and is_pos_integer(quantity) and
             (is_binary(mod_rank) or is_non_neg_integer(mod_rank)),
      do: Utils.string_map_to_struct(order, __MODULE__)
end
