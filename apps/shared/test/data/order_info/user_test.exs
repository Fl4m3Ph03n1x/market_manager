defmodule Shared.Data.OrderInfo.UserTest do
  @moduledoc false

  use ExUnit.Case

  alias Shared.Data.OrderInfo.User

  test "new/1 returns OrderInfo User" do
    data = %{
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
      }
    }

    assert User.new(data) == %User{
             ingame_name: "Fl4m3",
             slug: "fl4m3",
             status: :online,
             platform: :pc,
             crossplay: false
           }
  end
end
