defmodule AuctionHouse.Runtime.Server do
  @moduledoc """
  Process responsible for managing requests to the auction house.
  Talks to the logic layer and terminates gracefully.
  """

  use GenServer

  alias AuctionHouse.Data.{Authorization, Credentials, Order, User}
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
  def place_order(order), do: GenServer.call(__MODULE__, {:place_order, order}, @default_timeout)

  @spec delete_order(Type.order_id()) :: Type.delete_order_response()
  def delete_order(order_id),
    do: GenServer.call(__MODULE__, {:delete_order, order_id}, @default_timeout)

  @spec login(Credentials.t()) :: Type.login_response()
  def login(credentials), do: GenServer.call(__MODULE__, {:login, credentials}, @default_timeout)

  #############
  # Callbacks #
  #############

  @impl GenServer
  @spec init(nil) :: {:ok, Type.state(), {:continue, :setup_queue}}
  def init(nil) do
    Process.flag(:trap_exit, true)

    {
      :ok,
      %{
        dependencies: %{
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
        user: nil,
        authorization: nil
      },
      {:continue, :setup_queue}
    }
  end

  @impl GenServer
  @spec handle_continue(:setup_queue, Type.state()) :: {:noreply, Type.state()}
  def handle_continue(
        :setup_queue,
        %{
          dependencies: %{
            requests_queue: queue,
            requests_per_second: rps,
            create_queue_fn: create_queue
          }
        } = state
      ) do
    create_queue.(queue, [{:standard_rate, rps}])
    {:noreply, state}
  end

  @impl GenServer
  @spec handle_call(request :: {atom, any}, GenServer.from(), Type.state()) ::
          {:reply, reply :: any, new_state :: Type.state()}
  def handle_call({:place_order, order}, _from, state),
    do: {:reply, HTTPClient.place_order(order, state), state}

  @impl GenServer
  def handle_call({:delete_order, order_id}, _from, state),
    do: {:reply, HTTPClient.delete_order(order_id, state), state}

  @impl GenServer
  def handle_call({:get_all_orders, item_name}, _from, state),
    do: {:reply, HTTPClient.get_all_orders(item_name, state), state}

  @impl GenServer
  def handle_call(
        {:login, credentials},
        _from,
        state
      ) do
    authentication_result = HTTPClient.login(credentials, state)

    updated_state =
      case authentication_result do
        {:ok, {authorization, user}} ->
          state
          |> Map.put(:authorization, authorization)
          |> Map.put(:user, user)

        _ ->
          # in case we have successfully logged in the past, but failed now
          state
          |> Map.put(:authorization, nil)
          |> Map.put(:user, nil)
      end

    response =
      case authentication_result do
        {:ok, {_authorization, user}} -> {:ok, user}
        error -> error
      end

    {:reply, response, updated_state}
  end

  @impl GenServer
  @spec terminate(atom, any) :: any
  def terminate(_reason, %{dependencies: %{requests_queue: queue, delete_queue_fn: delete_queue}}),
    do: delete_queue.(queue)

  # If a process leaves normally, we ignore it.
  @impl GenServer
  def handle_info({:EXIT, _pid, :normal}, state), do: {:noreply, state}

  def child_spec(_), do: %{id: __MODULE__, start: {__MODULE__, :start_link, []}}
end
