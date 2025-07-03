defmodule Shared.Utils.MapsTest do
  @moduledoc false

  use ExUnit.Case

  alias Shared.Utils.Maps

  test "to_string_map/1 converts atom map to string map" do
    assert Maps.to_string_map(%{a: 1, b: 2}) == %{"a" => 1, "b" => 2}
  end

  test "to_atom_map/2 converts string map to atom map" do
    assert Maps.to_atom_map(%{"a" => 1, "b" => 2}) == %{a: 1, b: 2}
  end

  test "to_atom_map/2 converts string map to atom map and converts values as well" do
    assert Maps.to_atom_map(%{"a" => 1, "b" => "v"}, true) == %{a: 1, b: :v}
  end
end
