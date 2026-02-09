defmodule Shared.Data.OrderInfo.User do
  @moduledoc """
  Represents the account information for a warframe.market User who has an order
  posted. The current format is the following:

  ```json
  "user": {
    "id": "5962ff05d3ffb64d46e3c47f",
    "ingameName": "JeyciKon",
    "slug": "jeycikon",
    "reputation": 2,
    "platform": "pc",
    "crossplay": true,
    "locale": "pt",
    "status": "ingame",
    "activity": {
      "type": "UNKNOWN",
      "details": "unknown"
    }
  }
  ```

  We only take some of the information, not all.
  PC Players with crossplay active can trade with any platform (except Nintendo switch).
  https://www.warframe.com/crossprogression
  """

  use TypedStruct

  alias Shared.Utils.Structs

  @type ingame_name :: String.t()
  @type slug :: String.t()
  @type status :: :online | :offline | :ingame
  @type platform :: :pc
  @type crossplay :: boolean()

  @type user :: %{
          (ingame_name :: String.t()) => String.t(),
          (slug :: String.t()) => String.t(),
          (status :: String.t()) => String.t(),
          (platform :: String.t()) => String.t(),
          (crossplay :: String.t()) => boolean()
        }

  typedstruct enforce: true do
    @typedoc "Account information of an User"

    field(:ingame_name, ingame_name())
    field(:slug, slug())
    field(:status, status())
    field(:platform, platform())
    field(:crossplay, crossplay())
  end

  defguardp is_valid_status(status)
            when is_binary(status) and
                   (status == "online" or status == "offline" or
                      status == "ingame")

  defguardp is_valid_platform(platform) when is_binary(platform) and platform == "pc"

  @spec new(user) :: __MODULE__.t()
  def new(
        %{
          "ingameName" => ingame_name,
          "slug" => slug,
          "status" => status,
          "platform" => platform,
          "crossplay" => crossplay
        } = user
      )
      when is_binary(ingame_name) and is_binary(slug) and is_valid_status(status) and
             is_valid_platform(platform) and
             is_boolean(crossplay) do
    updated_user =
      user
      |> Map.put("status", String.to_atom(status))
      |> Map.put("platform", String.to_atom(platform))
      |> Map.put("ingame_name", ingame_name)

    Structs.string_map_to_struct(updated_user, __MODULE__)
  end
end
