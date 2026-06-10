defmodule Shared.Data.Product.ModWithoutRank do
  @moduledoc """
  Represents a mod without rank, i.e. a mod that has "n/a" as its rank.
  This is used for mods that do not have a rank, such as "Astral Autopsy".
  """

  import Shared.Utils.ExtraGuards

  use TypedStruct

  alias Jason
  alias Shared.Data.Product

  @behaviour Product

  @derive Jason.Encoder
  typedstruct enforce: true do
    @typedoc "ModWithoutRank details"

    field(:name, Product.name())
    field(:id, Product.id())
    field(:min_price, Product.min_price())
    field(:default_price, Product.default_price())
  end

  @spec new(Product.mod_without_rank()) :: __MODULE__.t()
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
  def to_sell_order!(%__MODULE__{} = mod, sell_price) do
    %{
      itemId: mod.id,
      type: "sell",
      visible: true,
      platinum: sell_price,
      quantity: 1
    }
  end
end
