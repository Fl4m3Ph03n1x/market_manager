defmodule AuctionHouse.Data.LoginInfo do
  @moduledoc """
  Represents the login information of a user. This information contains both
  the authorization for performing actions as the user as well as other user
  information that determines the range of actions available by the
  application's that use AuctionHouse.
  """

  use TypedStruct

  typedstruct enforce: true do
    @typedoc "Login Information for a user"

    field(:cookie, String.t())
    field(:token, String.t())
    field(:patreon?, boolean(), default: false)
  end

  @spec new(String.t(), String.t(), boolean()) :: __MODULE__.t()
  def new(cookie, token, patreon? \\ false) do
    %__MODULE__{
      cookie: cookie,
      token: token,
      patreon?: patreon?
    }
  end
end
