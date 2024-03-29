defmodule Shared.Data.OrderInfo do
  @moduledoc """
  Represents information about current orders from warframe market.
  """

  use TypedStruct

  import Shared.Utils.ExtraGuards

  alias Shared.Utils.Structs

  @type order_info :: %{
          (visible :: String.t()) => boolean(),
          (order_type :: String.t()) => String.t(),
          (platform :: String.t()) => String.t(),
          (platinum :: String.t()) => pos_integer(),
          (user :: String.t()) => __MODULE__.User.user()
        }

  typedstruct enforce: true do
    @typedoc "Information about an order"

    field(:visible, boolean())
    field(:order_type, String.t())
    field(:platform, String.t())
    field(:platinum, pos_integer())
    field(:user, __MODULE__.User.t())
  end

  @spec new(order_info) :: __MODULE__.t()
  def new(
        %{
          "visible" => visible,
          "order_type" => order_type,
          "platform" => platform,
          "platinum" => platinum,
          "user" => user
        } = order_info
      )
      when is_boolean(visible) and is_binary(order_type) and is_binary(platform) and
             is_pos_integer(platinum) and is_map(user) do
    order_info = Structs.string_map_to_struct(order_info, __MODULE__)
    user = Structs.string_map_to_struct(order_info.user, __MODULE__.User)
    Map.put(order_info, :user, user)
  end
end
