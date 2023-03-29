defmodule Shared.Data.Authorization do
  @moduledoc """
  Saves authorization details for a user.
  """

  use TypedStruct

  alias Shared.Utils.Structs

  @type authorization ::
          %{
            (cookie :: String.t()) => String.t(),
            (token :: String.t()) => String.t()
          }
          | [cookie: String.t(), token: String.t()]

  @derive Jason.Encoder
  typedstruct enforce: true do
    @typedoc "Authorization information for a user"

    field(:cookie, String.t())
    field(:token, String.t())
  end

  @spec new(authorization()) :: __MODULE__.t()
  def new(%{"cookie" => cookie, "token" => token} = auth)
      when is_binary(cookie) and is_binary(token) do
    Structs.string_map_to_struct(auth, __MODULE__)
  end

  def new([cookie: cookie, token: token] = auth)
      when is_binary(cookie) and is_binary(token),
      do: struct(__MODULE__, auth)
end

# defmodule Shared.Data.Authorization do
#   @moduledoc """
#   Saves authorization details for a user. It also contains other details.
#   """

#   alias Shared.Utils.Structs

#   @enforce_keys [:cookie, :token]
#   defstruct [:cookie, :token]

#   @type authorization :: %{
#           (cookie :: String.t()) => String.t(),
#           (token :: String.t()) => String.t()
#         }

#   @typedoc "Authorization information for a user"
#   @type t() :: %__MODULE__{
#           cookie: String.t(),
#           token: String.t()
#         }

#   @spec new(authorization()) :: t()
#   def new(%{"cookie" => cookie, "token" => token} = auth)
#       when is_binary(cookie) and is_binary(token) do
#     Structs.string_map_to_struct(auth, __MODULE__)
#   end
# end
