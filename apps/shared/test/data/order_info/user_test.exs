defmodule Shared.Data.OrderInfo.UserTest do
  @moduledoc false

  use ExUnit.Case

  alias Shared.Data.OrderInfo.User

  test "new/1 returns OrderInfo User" do
    assert User.new(%{"ingame_name" => "fl4m3", "status" => "online"}) ==
             %User{ingame_name: "fl4m3", status: "online"}
  end
end
