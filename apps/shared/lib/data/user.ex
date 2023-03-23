defmodule Shared.Data.User do
  @moduledoc """
  Represents relevant User information for clients using this AuctionHouse.
  """

  use TypedStruct

  alias Shared.Utils.Structs

  @type user :: %{
          (ingame_name :: String.t()) => String.t(),
          (patreon? :: String.t()) => boolean()
        }

  @derive Jason.Encoder
  typedstruct enforce: true do
    @typedoc "User information"

    field(:ingame_name, String.t())
    field(:patreon?, boolean(), default: false)
  end

  @spec new(user()) :: __MODULE__.t()
  def new(%{"ingame_name" => name, "patreon?" => patreon?} = user)
      when is_binary(name) and is_boolean(patreon?) do
    Structs.string_map_to_struct(user, __MODULE__)
  end
end
