defmodule Shared.Data.OrderInfo do
  @moduledoc """
  Represents information about current orders from warframe market.
  Here is the structure of a typical order in JSON:

  ```json
  {
      "creation_date": "2017-09-19T02:01:29.000+00:00",
      "visible": true,
      "quantity": 1,
      "user": {
          "reputation": 1977,
          "locale": "en",
          "avatar": "user/avatar/5678a156cbfa8f02c9b814c3.png?0d832d1017240078ecf4bdeb0d08a101",
          "ingame_name": "fl4m3",
          "last_seen": "2025-01-13T04:21:53.899+00:00",
          "crossplay": false,
          "platform": "pc",
          "id": "5678a156cbfa8f02c9b814c3",
          "region": "en",
          "status": "online"
      },
      "last_update": "2019-11-24T01:58:58.000+00:00",
      "platinum": 18,
      "order_type": "sell",
      "id": "59c07a790f31396e83ed709b",
      "mod_rank": 0,
      "region": "en"
  }
  ```

  Where the user is defined by OrderInfo.User.
  """

  use TypedStruct

  import Shared.Utils.ExtraGuards

  alias Shared.Utils.Structs
  alias __MODULE__.User

  @type visible :: boolean()
  @type order_type :: :sell | :buy
  @type platinum :: pos_integer()
  @type user :: __MODULE__.User.t()

  @type order_info :: %{
          (visible :: String.t()) => boolean(),
          (order_type :: String.t()) => String.t(),
          (platinum :: String.t()) => pos_integer(),
          (user :: String.t()) => __MODULE__.User.user()
        }

  typedstruct enforce: true do
    @typedoc "Information about an order"

    field(:visible, visible())
    field(:order_type, order_type())
    field(:platinum, platinum())
    field(:user, user())
  end

  defguardp is_valid_order_type(order_type)
            when is_binary(order_type) and (order_type == "sell" or order_type == "buy")

  @spec new(order_info) :: __MODULE__.t()
  def new(
        %{
          "visible" => visible,
          "order_type" => order_type,
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
