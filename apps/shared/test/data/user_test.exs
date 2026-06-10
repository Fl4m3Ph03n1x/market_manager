defmodule Shared.Data.UserTest do
  @moduledoc false

  use ExUnit.Case, async: true

  alias Shared.Data.User

  test "new/1 returns a User" do
    assert User.new(%{"ingame_name" => "Fl4m3", "slug" => "fl4m3", "patreon?" => false}) == %User{
             ingame_name: "Fl4m3",
             slug: "fl4m3",
             patreon?: false
           }

    assert User.new(ingame_name: "Fl4m3", slug: "fl4m3", patreon?: false) == %User{
             ingame_name: "Fl4m3",
             slug: "fl4m3",
             patreon?: false
           }
  end
end
