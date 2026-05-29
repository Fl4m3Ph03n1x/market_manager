defmodule RateLimiterTest do
  @moduledoc false

  use ExUnit.Case

  alias RateLimiter
  alias RateLimiter.LeakyBucket

  setup_all do

    supervisor_pid =
      case Task.Supervisor.start_link(name: RateLimiter.TaskSupervisor) do
        {:ok, pid} -> pid
        {:error, {:already_started, pid}} -> pid
      end

    implementation_pid =
      case LeakyBucket.start_link(%{requests_per_second: 1}) do
        {:ok, pid} -> pid
        {:error, {:already_started, pid}} -> pid
      end

    %{
      supervisor_pid: supervisor_pid,
      implementation_pid: implementation_pid
    }
  end

  test "enqueues requests and processes them at the correct rate", _config do
    pid = self()

    # Enqueue multiple requests
    for i <- 1..5 do
      request_handler = {fn v -> {:ok, v} end, [i]}

      response_handler =
        {fn response, %{} ->
           send(pid, {:response, response})
         end, %{}}

      RateLimiter.make_request(request_handler, response_handler)
    end

    Process.sleep(6100)

    # Assert that responses are received at the expected intervals
    assert_received {:response, {:ok, 1}}
    assert_received {:response, {:ok, 2}}
    assert_received {:response, {:ok, 3}}
    assert_received {:response, {:ok, 4}}
    assert_received {:response, {:ok, 5}}
  end

  test "handles empty queue correctly", _config do
    pid = self()

    # Wait for a tick to ensure the queue is empty
    Process.sleep(1100)

    # Enqueue a request after the queue has been empty
    request_handler = {fn -> :ok end, []}

    response_handler =
      {fn response, %{} ->
         send(pid, {:response, response})
       end, %{}}

    RateLimiter.make_request(request_handler, response_handler)

    Process.sleep(1100)

    assert_received {:response, :ok}
  end

  test "ensure process is not dead if task fails", %{
    implementation_pid: impl_pid,
    supervisor_pid: supervisor_pid
  } do
    test_pid = self()

    supervisor_ref = Process.monitor(supervisor_pid)
    impl_ref = Process.monitor(impl_pid)

    # Enqueue a request that will fail to test that the task failure does not crash the GenServer or Task.Supervisor
    request_handler = {fn -> raise "error" end, []}

    response_handler =
      {fn response, %{} ->
         send(test_pid, {:response, response})
       end, %{}}

    RateLimiter.make_request(request_handler, response_handler)

    Process.sleep(1100)

    # Test process should still be the same running process.
    assert self() == test_pid

    # Task.Supervisor should not die or get replaced.
    assert Process.whereis(RateLimiter.TaskSupervisor) == supervisor_pid
    refute_received {:DOWN, ^supervisor_ref, :process, ^supervisor_pid, _reason}

    # LeakyBucket should not die or get replaced.
    assert Process.whereis(LeakyBucket) == impl_pid
    refute_received {:DOWN, ^impl_ref, :process, ^impl_pid, _reason}

    Process.demonitor(supervisor_ref, [:flush])
    Process.demonitor(impl_ref, [:flush])
  end

  test "ensure process is not dead if multiple tasks fail", %{
    implementation_pid: impl_pid,
    supervisor_pid: supervisor_pid
  } do
    test_pid = self()

    supervisor_ref = Process.monitor(supervisor_pid)
    impl_ref = Process.monitor(impl_pid)

    for i <- 1..4 do
      request_handler =
        case i do
          1 ->
            {fn -> throw("a test error") end, []}

          2 ->
            {fn -> Process.exit(self(), :kill) end, []}

          _ ->
            {fn -> {:ok, i} end, []}
        end

      response_handler =
        case i do
          1 ->
            {fn response, %{} ->
               send(test_pid, {:response, response})
             end, %{}}

          2 ->
            {fn _, %{} -> throw("a test error") end, %{}}

          3 ->
            {fn _, %{} -> raise "a test error" end, %{}}

          4 ->
            {fn response, %{} ->
               send(test_pid, {:response, response})
             end, %{}}
        end

      RateLimiter.make_request(request_handler, response_handler)
    end

    # Wait for final response to ensure all tasks have been processed
    assert_receive {:response, {:ok, 4}}, 6000

    # Test process should still be the same running process.
    assert self() == test_pid

    # Task.Supervisor should not die or get replaced.
    assert Process.whereis(RateLimiter.TaskSupervisor) == supervisor_pid
    refute_received {:DOWN, ^supervisor_ref, :process, ^supervisor_pid, _reason}

    # LeakyBucket should not die or get replaced.
    assert Process.whereis(LeakyBucket) == impl_pid
    refute_received {:DOWN, ^impl_ref, :process, ^impl_pid, _reason}

    Process.demonitor(supervisor_ref, [:flush])
    Process.demonitor(impl_ref, [:flush])
  end

  test "calculates refresh rate correctly", _config do
    assert RateLimiter.calculate_refresh_rate(1) == 1000
    assert RateLimiter.calculate_refresh_rate(2) == 500
    assert RateLimiter.calculate_refresh_rate(5) == 200
    assert RateLimiter.calculate_refresh_rate(10) == 100
  end
end
