defmodule AuctionHouse.Runtime.Server do
  @moduledoc """
  Process responsible for managing requests to the auction house.
  Talks to the logic layer and terminates gracefully.
  """

  use GenServer

  alias AuctionHouse.Data.{Credentials, Order}
  alias AuctionHouse.Impl.{HTTPClient, Settings}
  alias AuctionHouse.Type
  alias Floki
  alias HTTPoison

  @default_timeout 20_000

  ##############
  # Public API #
  ##############

  @spec start_link :: :ignore | {:error, any} | {:ok, pid}
  def start_link, do: GenServer.start_link(__MODULE__, nil, name: __MODULE__)

  @spec get_all_orders(Type.item_name()) :: Type.get_all_orders_response()
  def get_all_orders(item_name),
    do: GenServer.call(__MODULE__, {:get_all_orders, item_name}, @default_timeout)

  @spec place_order(Order.t()) :: Type.place_order_response()
  def place_order(order), do: GenServer.call(__MODULE__, {:place_order, order})

  @spec delete_order(Type.order_id()) :: Type.delete_order_response()
  def delete_order(order_id),
    do: GenServer.call(__MODULE__, {:delete_order, order_id}, @default_timeout)

  @spec login(Credentials.t()) :: Type.login_response()
  def login(credentials), do: GenServer.call(__MODULE__, {:login, credentials})

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
        parse_document_fn: &Floki.parse_document/1,
        find_in_document_fn: &Floki.find/2,
        get_fn: &HTTPoison.get/3,
        post_fn: &HTTPoison.post/4,
        delete_fn: &HTTPoison.delete/3,
        run_fn: &:jobs.run/2,
        create_queue_fn: &:jobs.add_queue/2,
        delete_queue_fn: &:jobs.delete_queue/1,
        requests_queue: Settings.requests_queue(),
        requests_per_second: Settings.requests_per_second()
      },
      {:continue, :setup_queue}
    }
  end

  @impl GenServer
  @spec handle_continue(:setup_queue, map) :: {:noreply, map}
  def handle_continue(
        :setup_queue,
        %{
          requests_queue: queue,
          requests_per_second: rps,
          create_queue_fn: create_queue
        } = deps
      ) do
    create_queue.(queue, [{:standard_rate, rps}])
    {:noreply, deps}
  end

  @impl GenServer
  @spec handle_call(request :: {atom, any}, GenServer.from(), state :: map) ::
          {:reply, reply :: any, new_state :: map}
  def handle_call({:place_order, order}, _from, deps),
    do: {:reply, HTTPClient.place_order(order, deps), deps}

  @impl GenServer
  def handle_call({:delete_order, order_id}, _from, deps),
    do: {:reply, HTTPClient.delete_order(order_id, deps), deps}

  @impl GenServer
  def handle_call({:get_all_orders, item_name}, _from, deps),
    do: {:reply, HTTPClient.get_all_orders(item_name, deps), deps}

  @impl GenServer
  def handle_call(
        {:login, credentials},
        _from,
        deps
      ) do
    authentication_result = HTTPClient.login(credentials, deps)

    updated_state =
      case authentication_result do
        {:ok, authorization} -> Map.put(deps, :authorization, authorization)
        _ -> Map.put(deps, :authorization, nil)
      end

    {:reply, authentication_result, updated_state}
  end

  @impl GenServer
  @spec terminate(atom, any) :: any
  def terminate(_reason, %{requests_queue: queue, delete_queue_fn: delete_queue}),
    do: delete_queue.(queue)

  # If a process leaves normally, we ignore it.
  @impl GenServer
  def handle_info({:EXIT, _pid, :normal}, state), do: {:noreply, state}

  def child_spec(_) do
    %{id: __MODULE__, start: {__MODULE__, :start_link, []}}
  end
end
