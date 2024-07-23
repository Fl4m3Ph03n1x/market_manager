defmodule RateLimiter.LeakyBucket do
  @moduledoc """

  """

  use GenServer

  require Logger

  alias Qex

  @behaviour RateLimiter

  ##############
  # Public API #
  ##############

  def start_link(opts), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

  @impl RateLimiter
  def make_request(request_handler, response_handler),
    do: GenServer.cast(__MODULE__, {:enqueue_request, request_handler, response_handler})

  #############
  # Callbakcs #
  #############

  @impl GenServer
  def init(opts) do
    state = %{
      request_queue: Qex.new(),
      request_queue_size: 0,
      request_queue_poll_rate: RateLimiter.calculate_refresh_rate(opts.requests_per_second),
      send_after_ref: nil
    }

    {:ok, state, {:continue, :initial_timer}}
  end

  @impl GenServer
  def handle_continue(:initial_timer, state),
    do: {:noreply, %{state | send_after_ref: schedule_timer(state.request_queue_poll_rate)}}

  @impl GenServer
  def handle_cast({:enqueue_request, request_handler, response_handler}, state) do
    updated_queue = Qex.push(state.request_queue, {request_handler, response_handler})
    updated_size = state.request_queue_size + 1

    {:noreply, %{state | request_queue: updated_queue, request_queue_size: updated_size}}
  end

  @impl GenServer
  def handle_info(:tick, %{request_queue_size: 0} = state),
    do: {:noreply, %{state | send_after_ref: schedule_timer(state.request_queue_poll_rate)}}

  def handle_info(:tick, state) do
    {{:value, {request_handler, response_handler}}, poped_queue} = Qex.pop(state.request_queue)
    start_message = "Request started #{NaiveDateTime.utc_now()}"

    Task.Supervisor.async_nolink(RateLimiter.TaskSupervisor, fn ->
      {req_module, req_fun, args} = request_handler
      {resp_module, resp_fun} = response_handler

      response = apply(req_module, req_fun, args)
      apply(resp_module, resp_fun, [response])

      Logger.info("#{start_message}\nRequest completed #{NaiveDateTime.utc_now()}")
    end)

    {:noreply,
     %{
       state
       | request_queue: poped_queue,
         request_queue_size: state.request_queue_size - 1,
         send_after_ref: schedule_timer(state.request_queue_poll_rate)
     }}
  end

  def handle_info({ref, _result}, state) do
    # Task ended successfully, flush it from memory and continue
    Process.demonitor(ref, [:flush])

    {:noreply, state}
  end

  def handle_info({:DOWN, _ref, :process, _pid, :normal}, state) do
    # Task dies after successfull completion
    {:noreply, state}
  end

  def handle_info({:DOWN, _ref, :process, _pid, reason}, state) do
    # Taslk failed and died
    # TODO: find a way to enqueue request again
    Logger.error("Task failed with reason: #{reason}")
    {:noreply, state}
  end

  ###########
  # Private #
  ###########

  defp schedule_timer(rate), do: Process.send_after(self(), :tick, rate)
end
