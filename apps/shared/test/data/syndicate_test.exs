defmodule Shared.Data.SyndicateTest do
  @moduledoc false

  use ExUnit.Case

  alias Shared.Data.Syndicate

  test "new/1 returns a Syndicate" do
    assert Syndicate.new(%{"name" => "Red Veil", "id" => :red_veil}) ==
             %Syndicate{name: "Red Veil", id: :red_veil}

    assert Syndicate.new(%{"name" => "Red Veil", "id" => "red_veil"}) ==
             %Syndicate{name: "Red Veil", id: :red_veil}

    assert Syndicate.new(name: "Red Veil", id: :red_veil) ==
             %Syndicate{name: "Red Veil", id: :red_veil}
  end
end
