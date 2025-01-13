defmodule Shared.Data.OrderInfo.User do
  @moduledoc """
  Represents the account information for a warframe.market User who has an order
  posted. The current format is the following:

  ```json
  "user": {
      "reputation": 1977,
      "locale": "en",
      "avatar": "user/avatar/5678a156cbfa8f02c9b814c3.png?0d832d1017240078ecf4bdeb0d08a101",
      "ingame_name": "fl4m3",
      "last_seen": "2025-01-13T04:21:53.899+00:00",
      "crossplay": false,
      "platform": "pc",
      "id": "5678a156cbfa8f02c9b814c3",
      "region": "en",
      "status": "online"
  }
  ```

  We only take some of the information, no all.
  PC Players with crossplay active can trade with any platform (except Nintendo switch).
  https://www.warframe.com/crossprogression
  """

  use TypedStruct

  alias Shared.Utils.Structs

  @type ingame_name :: String.t()
  @type status :: :online | :offline | :ingame
  @type platform :: :pc
  @type crossplay :: boolean()

  @type user :: %{
          (ingame_name :: String.t()) => String.t(),
          (status :: String.t()) => String.t(),
          (platform :: String.t()) => String.t(),
          (crossplay :: String.t()) => boolean()
        }

  typedstruct enforce: true do
    @typedoc "Account information of an User"

    field(:ingame_name, ingame_name())
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
          "ingame_name" => ingame_name,
          "status" => status,
          "platform" => platform,
          "crossplay" => crossplay
        } = user
      )
      when is_binary(ingame_name) and is_valid_status(status) and is_valid_platform(platform) and
             is_boolean(crossplay) do
    updated_user =
      user
      |> Map.put("status", String.to_existing_atom(status))
      |> Map.put("platform", String.to_existing_atom(platform))

    Structs.string_map_to_struct(updated_user, __MODULE__)
  end
end
