defmodule AuctionHouse.Server do
  @moduledoc """
  Process responsible for managing requests to the auction house.
  Talks to the logic layer and terminates gracefully.
  """

  use GenServer

  alias AuctionHouse
  alias AuctionHouse.{HTTPClient, Settings}

  ##############
  # Public API #
  ##############

  @spec start_link(any) :: :ignore | {:error, any} | {:ok, pid}
  def start_link(_), do: GenServer.start_link(__MODULE__, nil, name: __MODULE__)

  @spec get_all_orders(AuctionHouse.item_name) :: AuctionHouse.get_all_orders_response
  def get_all_orders(item_name), do:
    GenServer.call(__MODULE__, {:get_all_orders, item_name})

  @spec place_order(AuctionHouse.order) :: AuctionHouse.place_order_response
  def place_order(order), do:
    GenServer.call(__MODULE__, {:place_order, order})

  @spec delete_order(AuctionHouse.order_id) :: AuctionHouse.delete_order_response
  def delete_order(order_id), do:
    GenServer.call(__MODULE__, {:delete_order, order_id})

  #############
  # Callbacks #
  #############

  @impl GenServer
  @spec init(nil) :: {:ok, map, {:continue, :setup_queue}}
  def init(nil) do
    Process.flag(:trap_exit, true)
    {
      :ok,
      %{
        get_fn: &HTTPoison.get/2,
        post_fn: &HTTPoison.post/3,
        delete_fn: &HTTPoison.delete/2,
        run_fn: &:jobs.run/2,
        requests_queue: Settings.requests_queue(),
        requests_per_second: Settings.requests_per_second(),
        create_queue_fn: &:jobs.add_queue/2,
        delete_queue_fn: &:jobs.delete_queue/1
      },
      {:continue, :setup_queue}
    }
  end

  @impl GenServer
  @spec handle_continue(:setup_queue, map) :: {:noreply, map}
  def handle_continue(:setup_queue, %{
    requests_queue: queue,
    requests_per_second: rps,
    create_queue_fn: create_queue
    } = deps)
  do
    create_queue.(queue, [{:standard_rate, rps}])
    {:noreply, deps}
  end

  @impl GenServer
  @spec handle_call({atom, any}, {pid, any}, map) :: {:reply, any, map}
  def handle_call({:place_order, order}, _from, deps), do:
    {:reply, HTTPClient.place_order(order, deps), deps}

  @impl GenServer
  def handle_call({:delete_order, order_id}, _from, deps), do:
    {:reply, HTTPClient.delete_order(order_id, deps), deps}

  @impl GenServer
  def handle_call({:get_all_orders, item_name}, _from, deps), do:
    {:reply, HTTPClient.get_all_orders(item_name, deps), deps}

  @impl GenServer
  @spec terminate(atom, any) :: any
  def terminate(_reason, %{requests_queue: queue, delete_queue_fn: delete_queue}), do:
    delete_queue.(queue)

  # If a process leaves normally, we ignore it.
  @impl GenServer
  def handle_info({:EXIT, _pid, :normal}, state), do: {:noreply, state}

end
