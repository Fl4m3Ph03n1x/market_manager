defmodule Shared.Data.OrderInfo do
  @moduledoc """
  Represents information about current orders from warframe market.
  Here is the structure of a typical order in JSON:

  ```json
  {
    "id": "598bd5b10f3139463a86b6af",
    "type": "sell",
    "platinum": 22,
    "quantity": 1,
    "perTrade": 1,
    "rank": 0,
    "visible": true,
    "createdAt": "2017-08-10T03:40:33Z",
    "updatedAt": "2026-01-29T02:51:53Z",
    "itemId": "54e644ffe779897594fa68d2",
    "user": {
      "id": "5962ff05d3ffb64d46e3c47f",
      "ingameName": "JeyciKon",
      "slug": "jeycikon",
      "reputation": 2,
      "platform": "pc",
      "crossplay": true,
      "locale": "pt",
      "status": "ingame",
      "activity": {
        "type": "UNKNOWN",
        "details": "unknown"
      },
      "lastSeen": "2026-02-06T05:46:21Z"
    }
  }
  ```

  Where the user is defined by OrderInfo.User.
  """

  use TypedStruct

  import Shared.Utils.ExtraGuards

  alias __MODULE__.User
  alias Shared.Utils.Structs

  @type visible :: boolean()
  @type order_type :: :sell | :buy
  @type platinum :: pos_integer()
  @type user :: __MODULE__.User.t()
  @type rank :: non_neg_integer()

  @type order_info :: %{
          required(visible :: String.t()) => boolean(),
          required(type :: String.t()) => String.t(),
          required(platinum :: String.t()) => pos_integer(),
          optional(rank :: String.t()) => non_neg_integer(),
          required(user :: String.t()) => __MODULE__.User.user()
        }

  typedstruct do
    @typedoc "Information about an order"

    field(:visible, visible(), enforce: true)
    field(:order_type, order_type(), enforce: true)
    field(:platinum, platinum(), enforce: true)
    field(:rank, rank())
    field(:user, user(), enforce: true)
  end

  @spec new(order_info()) :: __MODULE__.t()
  def new(
        %{
          "visible" => visible,
          "type" => order_type,
          "platinum" => platinum,
          "rank" => rank,
          "user" => user
        } = order_info
      )
      when is_boolean(visible) and is_valid_order_type(order_type) and
             is_pos_integer(platinum) and is_non_neg_integer(rank) and is_map(user) do
    order_info
    |> Map.put("order_type", String.to_atom(order_type))
    |> Structs.string_map_to_struct(__MODULE__)
    |> Map.put(:user, User.new(user))
  end

  @spec new(order_info()) :: __MODULE__.t()
  def new(
        %{
          "visible" => visible,
          "type" => order_type,
          "platinum" => platinum,
          "user" => user
        } = order_info
      )
      when is_boolean(visible) and is_valid_order_type(order_type) and
             is_pos_integer(platinum) and is_map(user) do
    order_info
    |> Map.put("order_type", String.to_atom(order_type))
    |> Structs.string_map_to_struct(__MODULE__)
    |> Map.put(:user, User.new(user))
  end
end
