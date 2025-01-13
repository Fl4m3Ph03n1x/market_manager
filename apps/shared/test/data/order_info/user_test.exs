defmodule Shared.Data.OrderInfo.UserTest do
  @moduledoc false

  use ExUnit.Case

  alias Shared.Data.OrderInfo.User

  test "new/1 returns OrderInfo User" do
    data = %{
      "avatar" => "user/avatar/5678a156cbfa8f02c9b814c3.png?0d832d1017240078ecf4bdeb0d08a101",
      "crossplay" => false,
      "id" => "5678a156cbfa8f02c9b814c3",
      "ingame_name" => "fl4m3",
      "last_seen" => "2025-01-13T04:21:53.899+00:00",
      "locale" => "en",
      "platform" => "pc",
      "region" => "en",
      "reputation" => 1977,
      "status" => "online"
    }

    assert User.new(data) == %User{
             ingame_name: "fl4m3",
             status: :online,
             platform: :pc,
             crossplay: false
           }
  end
end
