defmodule Shared.Utils.TuplesTest do
  @moduledoc false

  use ExUnit.Case

  alias Shared.Utils.Tuples

  test "to_tagged_tuple/1 converts data to OK tagged tuple" do
    assert Tuples.to_tagged_tuple(1) == {:ok, 1}
  end

  test "from_tagged_tuple/1 returns data from tagged tuple" do
    assert Tuples.from_tagged_tuple({:ok, 1}) == 1
  end

  test "is_ok? returns true is tagged tuple is OK" do
    assert Tuples.is_ok?({:ok, 1})
  end

  test "is_ok? returns false is tagged tuple is NOK" do
    refute Tuples.is_ok?({:error, 1})
  end
end
