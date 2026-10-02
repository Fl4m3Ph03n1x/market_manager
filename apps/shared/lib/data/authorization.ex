defmodule Shared.Data.Authorization do
  @moduledoc """
  Saves authorization details for a user.
  """

  use TypedStruct

  alias Shared.Utils.Structs

  @type access_token :: String.t()

  @type authorization :: %{(access_token :: String.t()) => String.t()}

  @derive Jason.Encoder
  @derive {Inspect, except: [:access_token]}
  typedstruct enforce: true do
    @typedoc "Authorization information for a user. `access_token` is the bare JWT, without any scheme prefix."

    field(:access_token, access_token())
  end

  @spec new(authorization()) :: __MODULE__.t()
  def new(%{"access_token" => access_token} = auth)
      when is_binary(access_token) and access_token != "" do
    Structs.string_map_to_struct(auth, __MODULE__)
  end
end
