defmodule Shared.Data.Product do
  @moduledoc """
  A Product is an item we can create a sell order for. Currently we only
  support mods. Products contain warframe.market information about the item, as
  well as default parameters to create sell orders.
  """

  use TypedStruct

  import Shared.Utils.ExtraGuards

  alias Shared.Utils.Structs

  @type id :: String.t()
  @type name :: String.t()
  @type min_price :: pos_integer()
  @type default_price :: pos_integer()
  @type quantity :: pos_integer()
  @type rank :: non_neg_integer() | String.t()

  @type product ::
          %{
            (name :: String.t()) => String.t(),
            (id :: String.t()) => String.t(),
            (min_price :: String.t()) => pos_integer(),
            (default_price :: String.t()) => pos_integer(),
            (quantity :: String.t()) => pos_integer(),
            (rank :: String.t()) => non_neg_integer() | String.t()
          }
          | %{
              (name :: String.t()) => String.t(),
              (id :: String.t()) => String.t(),
              (min_price :: String.t()) => pos_integer(),
              (default_price :: String.t()) => pos_integer()
            }
          | [
              name: String.t(),
              id: String.t(),
              min_price: pos_integer(),
              default_price: pos_integer()
            ]

  @derive Jason.Encoder
  typedstruct enforce: true do
    @typedoc "Product details"

    field(:name, name())
    field(:id, id())
    field(:min_price, min_price())
    field(:default_price, default_price())
    field(:quantity, quantity())
    field(:rank, rank())
  end

  @spec new(product()) :: __MODULE__.t()
  def new(
        %{
          "name" => name,
          "id" => id,
          "min_price" => min_price,
          "default_price" => default_price,
          "rank" => rank
        } = product
      )
      when is_binary(name) and is_binary(id) and is_pos_integer(min_price) and
             is_pos_integer(default_price) and (is_non_neg_integer(rank) or is_binary(rank)) do
    product
    |> Map.put("quantity", 1)
    |> Structs.string_map_to_struct(__MODULE__)
  end

  def new(%{
        "name" => name,
        "id" => id,
        "min_price" => min_price,
        "default_price" => default_price
      })
      when is_binary(name) and is_binary(id) and is_pos_integer(min_price) and
             is_pos_integer(default_price) do
    __MODULE__.new(%{
      "name" => name,
      "id" => id,
      "min_price" => min_price,
      "default_price" => default_price,
      "quantity" => 1,
      "rank" => 0
    })
  end

  def new([name: name, id: id, min_price: min_price, default_price: default_price] = product)
      when is_binary(name) and is_binary(id) and is_pos_integer(min_price) and
             is_pos_integer(default_price) do
    struct(__MODULE__, product ++ [quantity: 1, rank: 0])
  end
end
