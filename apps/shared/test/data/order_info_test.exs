defmodule Shared.Data.OrderInfoTest do
  @moduledoc false

  use ExUnit.Case

  alias Shared.Data.OrderInfo
  alias Shared.Data.OrderInfo.User

  test "new/1 returns OrderInfo" do
    data = %{
      "creation_date" => "2017-09-19T02:01:29.000+00:00",
      "id" => "59c07a790f31396e83ed709b",
      "last_update" => "2019-11-24T01:58:58.000+00:00",
      "mod_rank" => 0,
      "order_type" => "sell",
      "platinum" => 18,
      "quantity" => 1,
      "region" => "en",
      "user" => %{
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
      },
      "visible" => true
    }

    assert OrderInfo.new(data) == %OrderInfo{
             visible: true,
             order_type: :sell,
             platinum: 18,
             user: %User{
               ingame_name: "fl4m3",
               status: :online,
               platform: :pc,
               crossplay: false
             }
           }
  end
end
