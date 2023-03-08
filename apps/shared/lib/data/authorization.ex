defmodule Shared.Data.Authorization do
  @moduledoc """
  Saves authorization details for a user. It also contains other details.
  """

  use TypedStruct

  typedstruct enforce: true do
    @typedoc "Authorization information for a user"

    field(:cookie, String.t())
    field(:token, String.t())
  end

  @spec new(String.t(), String.t()) :: __MODULE__.t()
  def new(cookie, token)
      when is_binary(cookie) and is_binary(token) do
    %__MODULE__{
      cookie: cookie,
      token: token
    }
  end
end
