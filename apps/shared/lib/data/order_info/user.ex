defmodule Shared.Data.OrderInfo.User do
  @moduledoc """
  Represents the account information for a warframe.market User who has an order
  posted.
  """

  use TypedStruct

  alias Shared.Utils.Structs

  @type ingame_name :: String.t()
  @type status :: String.t()

  @type user :: %{
          (ingame_name :: String.t()) => String.t(),
          (status :: String.t()) => String.t()
        }

  typedstruct enforce: true do
    @typedoc "Account information of an User"

    field(:ingame_name, ingame_name())
    field(:status, status())
  end

  @spec new(user) :: __MODULE__.t()
  def new(
        %{
          "ingame_name" => ingame_name,
          "status" => status
        } = user
      )
      when is_binary(ingame_name) and is_binary(status),
      do: Structs.string_map_to_struct(user, __MODULE__)
end
