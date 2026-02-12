defmodule Shared.Data.OrderInfoTest do
  @moduledoc false

  use ExUnit.Case

  alias Shared.Data.OrderInfo
  alias Shared.Data.OrderInfo.User

  test "new/1 returns OrderInfo" do
    data =
      %{
        "id" => "598bd5b10f3139463a86b6af",
        "type" => "sell",
        "platinum" => 18,
        "quantity" => 1,
        "perTrade" => 1,
        "rank" => 0,
        "visible" => true,
        "createdAt" => "2017-08-10T03:40:33Z",
        "updatedAt" => "2026-01-29T02:51:53Z",
        "itemId" => "54e644ffe779897594fa68d2",
        "user" => %{
          "id" => "5962ff05d3ffb64d46e3c47f",
          "ingameName" => "Fl4m3",
          "slug" => "fl4m3",
          "reputation" => 2,
          "platform" => "pc",
          "crossplay" => false,
          "locale" => "pt",
          "status" => "online",
          "activity" => %{
            "type" => "UNKNOWN",
            "details" => "unknown"
          },
          "lastSeen" => "2026-02-06T05:46:21Z"
        }
      }

    assert OrderInfo.new(data) == %OrderInfo{
             visible: true,
             order_type: :sell,
             platinum: 18,
             user: %User{
               ingame_name: "Fl4m3",
               slug: "fl4m3",
               status: :online,
               platform: :pc,
               crossplay: false
             }
           }
  end
end
