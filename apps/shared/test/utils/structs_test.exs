defmodule Shared.Utils.StructsTest do
  @moduledoc false

  use ExUnit.Case

  alias Shared.Utils.Structs

  describe "string_map_to_struct/2" do
    alias Shared.Utils.StructsTest.Test

    test "converts string map to Struct" do
      assert Structs.string_map_to_struct(%{"a" => 1, "b" => 2}, Test) ==
               Test.new(1, 2)
    end
  end

  defmodule Test do
    @moduledoc false
    defstruct a: 0, b: 0

    def new(a, b), do: struct(__MODULE__, %{a: a, b: b})
  end
end
