defmodule Shared.Data.Product.Mod do
  @moduledoc """
  Represents a Mod with rank.
  Even though these mods have a rank, the rank is not used to calculate the price, so the derankify_order function just returns the order as it is.
  This choice was made because there is no defined algorithm that clearly maps Endo (the resource used to rank up mods) to a specific price adjustment.
  """

  import Shared.Utils.ExtraGuards

  use TypedStruct

  alias Jason
  alias Shared.Data.Product

  @behaviour Product

  @derive Jason.Encoder
  typedstruct do
    @typedoc "Mod details"

    field(:name, Product.name(), enforce: true)
    field(:id, Product.id(), enforce: true)
    field(:min_price, Product.min_price(), enforce: true)
    field(:default_price, Product.default_price(), enforce: true)
    field(:subtype, Product.subtype())
  end

  @spec new(Product.mod()) :: __MODULE__.t()
  def new(%{
        "name" => name,
        "id" => id,
        "min_price" => min_price,
        "default_price" => default_price,
        "subtype" => subtype
      })
      when is_binary(name) and is_binary(id) and is_pos_integer(min_price) and
             is_pos_integer(default_price) and is_valid_subtype(subtype) do
    %__MODULE__{
      name: name,
      id: id,
      min_price: min_price,
      default_price: default_price,
      subtype: subtype
    }
  end

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
      default_price: default_price
    }
  end

  @impl Product
  def derankify_order(order), do: order

  @impl Product
  def to_sell_order!(%__MODULE__{subtype: subtype} = mod, sell_price)
      when is_valid_subtype(subtype) do
    %{
      itemId: mod.id,
      type: "sell",
      visible: true,
      platinum: sell_price,
      quantity: 1,
      rank: 0,
      subtype: subtype
    }
  end

  def to_sell_order!(%__MODULE__{} = mod, sell_price) do
    %{
      itemId: mod.id,
      type: "sell",
      visible: true,
      platinum: sell_price,
      quantity: 1,
      rank: 0
    }
  end
end
