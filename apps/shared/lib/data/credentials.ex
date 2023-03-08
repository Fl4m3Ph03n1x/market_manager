defmodule Shared.Data.Credentials do
  @moduledoc """
  Represents the authentication data for an user.
  """

  use TypedStruct

  @derive Jason.Encoder
  typedstruct enforce: true do
    @typedoc "The credentials"

    field(:email, String.t())
    field(:password, String.t())
  end

  @spec new(email :: String.t(), password :: String.t()) :: __MODULE__.t()
  def new(email, password) when is_binary(email) and is_binary(password),
    do: %__MODULE__{
      email: email,
      password: password
    }
end
