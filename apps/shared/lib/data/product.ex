defmodule Shared.Data.Product do
  @moduledoc """
  A Product is an item we can create a sell order for. Products contain warframe.market information about the item, as
  well as default parameters to create sell orders.
  The types are used to determine which struct to create when parsing products from the JSON file read from the store.
  """

  alias Shared.Data.OrderInfo
  alias Shared.Data.Product.{Arcane, Mod, ModWithoutRank}

  @type id :: String.t()
  @type name :: String.t()
  @type min_price :: pos_integer()
  @type default_price :: pos_integer()
  @type quantity :: pos_integer()
  @type per_trade :: pos_integer()
  @type rank :: non_neg_integer() | String.t()
  @type type :: String.t()
  @type subtype :: String.t()
  @type sell_price :: pos_integer()
  @type sell_order :: map()

  @type mod_without_rank :: %{
          required(name :: String.t()) => String.t(),
          required(id :: String.t()) => String.t(),
          required(min_price :: String.t()) => pos_integer(),
          required(default_price :: String.t()) => pos_integer(),
          required(type :: String.t()) => String.t()
        }

  @type mod :: %{
          required(name :: String.t()) => String.t(),
          required(id :: String.t()) => String.t(),
          required(min_price :: String.t()) => pos_integer(),
          required(default_price :: String.t()) => pos_integer(),
          required(type :: String.t()) => String.t(),
          optional(subtype :: String.t()) => String.t()
        }

  @type arcane :: %{
          required(name :: String.t()) => String.t(),
          required(id :: String.t()) => String.t(),
          required(min_price :: String.t()) => pos_integer(),
          required(default_price :: String.t()) => pos_integer(),
          required(quantity :: String.t()) => pos_integer(),
          required(type :: String.t()) => String.t()
        }

  @type product :: mod() | mod_without_rank() | arcane()

  @type t :: Arcane.t() | Mod.t() | ModWithoutRank.t()

  @doc """
  Converts a ranked OrderInfo (which came from warframe.market) to its unranked equivalent by adjusting the platinum price based on the rank multiplier.
  The rank multiplier differs from product to product, so this function is implemented in each Product.
  """
  @callback derankify_order(OrderInfo.t()) :: OrderInfo.t()

  @doc """
  This operation is used when creating sell orders to be posted on warframe.market, as the API expects a JSON body with specific fields.
  The exact fields and their values can differ based on the type of product, so this function is implemented in each Product.
  """
  @callback to_sell_order!(__MODULE__.t(), sell_price()) :: sell_order()

  @doc """
  Helper function to invoke the derankify_order function of the correct Product without having to know which specific struct it is.
  """
  @spec derankify_order(__MODULE__.t(), OrderInfo.t()) :: OrderInfo.t()
  def derankify_order(product, %OrderInfo{} = order) do
    module = product.__struct__
    module.derankify_order(order)
  end

  @doc """
  Helper function to invoke the to_sell_order! function of the correct Product without having to know which specific struct it is.
  """
  @spec to_sell_order!(__MODULE__.t(), sell_price()) :: sell_order()
  def to_sell_order!(product, sell_price) do
    module = product.__struct__
    module.to_sell_order!(product, sell_price)
  end

  @spec new(product()) :: __MODULE__.t()
  def new(%{"type" => "mod_without_rank"} = unranked_mod), do: ModWithoutRank.new(unranked_mod)

  def new(%{"type" => "arcane"} = arcane), do: Arcane.new(arcane)

  def new(%{"type" => "mod"} = mod), do: Mod.new(mod)
end
