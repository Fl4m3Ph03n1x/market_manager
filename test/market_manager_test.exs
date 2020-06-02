defmodule MarketManagerTest do
  use ExUnit.Case
  doctest MarketManager

  test "greets the world" do
    assert MarketManager.hello() == :world
  end
end
