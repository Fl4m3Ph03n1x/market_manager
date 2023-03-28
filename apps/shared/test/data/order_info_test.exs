defmodule Shared.Data.OrderInfoTest do
  @moduledoc false

  use ExUnit.Case

  alias Shared.Data.OrderInfo
  alias Shared.Data.OrderInfo.User

  test "new/1 returns OrderInfo" do
    assert OrderInfo.new(%{
             "visible" => true,
             "order_type" => "sell",
             "platform" => "pc",
             "platinum" => 14,
             "user" => %{
               "ingame_name" => "fl4m3",
               "status" => "online"
             }
           }) == %OrderInfo{
             visible: true,
             order_type: "sell",
             platform: "pc",
             platinum: 14,
             user: %User{
               ingame_name: "fl4m3",
               status: "online"
             }
           }
  end
end
