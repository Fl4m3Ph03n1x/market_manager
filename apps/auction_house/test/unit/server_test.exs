defmodule AuctionHouse.ServerTest do
  @moduledoc false

  use ExUnit.Case

  alias AuctionHouse
  alias AuctionHouse.Runtime.Server

  test "init/1 returns the correct state" do
    # Act
    {:ok, deps, {:continue, :setup_queue}} = Server.init(nil)

    # Assert
    assert is_function(Map.get(deps, :parse_document_fn))
    assert is_function(Map.get(deps, :find_in_document_fn))
    assert is_function(Map.get(deps, :get_fn))
    assert is_function(Map.get(deps, :post_fn))
    assert is_function(Map.get(deps, :delete_fn))
    assert is_function(Map.get(deps, :create_queue_fn))
    assert is_function(Map.get(deps, :delete_queue_fn))
    assert is_function(Map.get(deps, :run_fn))
    assert is_integer(Map.get(deps, :requests_per_second))
    assert is_atom(Map.get(deps, :requests_queue))
  end

  test "handle_continue/2 creates queue" do
    # Arrange
    deps = %{
      requests_queue: :test_queue,
      requests_per_second: 2,
      create_queue_fn: fn _name, _opts ->
        send(self(), {:add_queue, :ok})
        :ok
      end
    }

    # Act
    actual = Server.handle_continue(:setup_queue, deps)
    expected = {:noreply, deps}

    # Assert
    assert actual == expected
    assert_received {:add_queue, :ok}
  end

  test "terminate/2 deletes queue" do
    # Arrange
    deps = %{
      requests_queue: :test_queue,
      requests_per_second: 2,
      delete_queue_fn: fn _name ->
        send(self(), {:delete_queue, true})
        true
      end
    }

    # Act and Assert
    assert Server.terminate(nil, deps)
    assert_received {:delete_queue, true}
  end

  test "returns child_spec correctly" do
    # Arrange
    expected = %{id: Server, start: {Server, :start_link, []}}
    actual = AuctionHouse.child_spec(nil)

    # Assert
    assert actual == expected
  end
end
