defmodule Manager.ServerTest do
  use ExUnit.Case

  alias Manager
  alias Manager.Runtime.Server

  test "init/1 returns the correct state" do
    # Act & Assert
    assert {:ok, {_opts, _children}} = Server.init(nil)
  end

  test "returns child_spec correctly" do
    # Act & Assert
    assert %{
             id: Server,
             start: {Server, :start_link, [nil]},
             type: :supervisor
           } = Manager.child_spec(nil)
  end
end
