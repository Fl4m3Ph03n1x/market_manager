defmodule Shared.Data.Product.Arcane do
  @moduledoc """
  Module representing Arcane products in Warframe.
  It includes functionality to convert ranked Arcane orders to their unranked equivalents for better price comparisons.
  """

  import Shared.Utils.ExtraGuards

  use TypedStruct

  alias Jason
  alias Shared.Data.{OrderInfo, Product}

  @behaviour Product

  @derive Jason.Encoder
  typedstruct enforce: true do
    @typedoc "Arcane details"

    field(:name, Product.name())
    field(:id, Product.id())
    field(:min_price, Product.min_price())
    field(:default_price, Product.default_price())
    field(:quantity, Product.quantity())
    field(:rank, Product.rank())
    field(:per_trade, Product.per_trade())
  end

  @rank_conversion %{
    1 => 3,
    2 => 6,
    3 => 10,
    4 => 15,
    5 => 21
  }

  @impl Product
  def derankify_order(%OrderInfo{platinum: plat, rank: rank} = order) when is_pos_integer(rank) do
    derankified_price = round(plat / @rank_conversion[rank])
    %OrderInfo{order | platinum: derankified_price, rank: 0}
  end

  def derankify_order(%OrderInfo{} = order), do: order

  @spec new(Product.arcane()) :: __MODULE__.t()
  def new(%{
        "name" => name,
        "id" => id,
        "min_price" => min_price,
        "default_price" => default_price,
        "quantity" => quantity,
        "per_trade" => per_trade
      })
      when is_binary(name) and is_binary(id) and is_pos_integer(min_price) and
             is_pos_integer(default_price) and is_pos_integer(quantity) and
             is_pos_integer(per_trade),
      do: %__MODULE__{
        name: name,
        id: id,
        min_price: min_price,
        default_price: default_price,
        quantity: quantity,
        rank: 0,
        per_trade: per_trade
      }
end
