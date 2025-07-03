defmodule Shared.Data.Credentials do
  @moduledoc """
  Represents the credentials of an user. Credentials are used to get access
  to Authorization and User info, which is the used to makes requests to the
  market.
  """

  use TypedStruct

  @type email :: String.t()
  @type password :: String.t()

  @derive Jason.Encoder
  typedstruct enforce: true do
    @typedoc "The credentials"

    field(:email, email())
    field(:password, password())
  end

  @spec new(email :: String.t(), password :: String.t()) :: __MODULE__.t()
  def new(email, password) when is_binary(email) and is_binary(password),
    do: %__MODULE__{
      email: email,
      password: password
    }
end
