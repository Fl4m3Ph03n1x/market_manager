defmodule Shared.Data.Product.Mod do
  @moduledoc """
  Represents a Mod with rank.
  Even though these mods have a rank, the rank is not used to calculate the price, so the derankify_order function just returns the order as it is.
  This choice was made because there is no defined algorithm that clearly maps Endo (the resource used to rank up mods) to a specific price adjustment.
  """

  import Shared.Utils.ExtraGuards

  use TypedStruct

  alias Shared.Data.Product
  alias Jason

  @behaviour Product

  @derive Jason.Encoder
  typedstruct enforce: true do
    @typedoc "Mod details"

    field(:name, Product.name())
    field(:id, Product.id())
    field(:min_price, Product.min_price())
    field(:default_price, Product.default_price())
    field(:quantity, Product.quantity())
    field(:rank, Product.rank())
  end

  @impl Product
  def derankify_order(order), do: order

  @spec new(Product.mod()) :: __MODULE__.t()
  def new(%{
        "name" => name,
        "id" => id,
        "min_price" => min_price,
        "default_price" => default_price
      })
      when is_binary(name) and is_binary(id) and is_pos_integer(min_price) and
             is_pos_integer(default_price) do
    %__MODULE__{
      name: name,
      id: id,
      min_price: min_price,
      default_price: default_price,
      quantity: 1,
      rank: 0
    }
  end
end
