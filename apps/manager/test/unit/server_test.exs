defmodule Manager.ServerTest do
  @moduledoc false

  use ExUnit.Case

  alias Manager
  alias Manager.Runtime.Server

  test "init/1 returns the correct state" do
    # Act & Assert
    assert {:ok, {_opts, _children}} = Server.init(nil)
  end

  test "returns child_spec correctly" do
    # Act & Assert
    assert Manager.child_spec(nil) ==  %{
      id: Server,
      start: {Server, :start_link, []}
    }
  end
end
