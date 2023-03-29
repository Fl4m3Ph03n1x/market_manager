defmodule Shared.Data.UserTest do
  @moduledoc false

  use ExUnit.Case

  alias Shared.Data.User

  test "new/1 returns a User" do
    assert User.new(%{"ingame_name" => "fl4m3", "patreon?" => false}) == %User{
             ingame_name: "fl4m3",
             patreon?: false
           }

    assert User.new(ingame_name: "fl4m3", patreon?: false) == %User{
             ingame_name: "fl4m3",
             patreon?: false
           }
  end
end
