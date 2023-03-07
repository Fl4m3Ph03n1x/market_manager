defmodule AuctionHouse.Data.User do
  @moduledoc """
  Represents relevant User information for clients using this AuctionHouse.
  """

  use TypedStruct

  typedstruct enforce: true do
    @typedoc "User information"

    field(:ingame_name, String.t())
    field(:patreon?, boolean(), default: false)
  end

  @spec new(ingame_name :: String.t(), patreon? :: boolean()) :: __MODULE__.t()
  def new(ingame_name, patreon? \\ false)
      when is_binary(ingame_name) and is_boolean(patreon?) do
    %__MODULE__{
      ingame_name: ingame_name,
      patreon?: patreon?
    }
  end
end
