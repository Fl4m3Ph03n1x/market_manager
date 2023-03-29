defmodule Shared.Utils.MapsTest do
  @moduledoc false

  use ExUnit.Case

  alias Shared.Utils.Maps

  test "to_string_map/1 converts atom map to string map" do
    assert Maps.to_string_map(%{a: 1, b: 2}) == %{"a" => 1, "b" => 2}
  end
end
