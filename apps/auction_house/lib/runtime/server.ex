defmodule AuctionHouse.Runtime.Server do
  @moduledoc """
  Process responsible for managing requests to the auction house.
  Talks to the logic layer and terminates gracefully.
  """

  use GenServer

  alias AuctionHouse.Impl.{HTTPClient, Settings}
  alias AuctionHouse.Type
  alias Floki
  alias HTTPoison
  alias Shared.Data.{Authorization, Credentials, Order, PlacedOrder, User}

  @genserver_timeout Application.compile_env!(:auction_house, :genserver_timeout)

  ##############
  # Public API #
  ##############

  @spec start_link :: :ignore | {:error, any} | {:ok, pid}
  def start_link,
    do: GenServer.start_link(__MODULE__, nil, name: __MODULE__)

  @spec start_link(String.t(), pos_integer()) :: :ignore | {:error, any} | {:ok, pid}
  def start_link(suffix, count) when is_binary(suffix) and is_integer(count) and count >= 0,
    do: GenServer.start_link(__MODULE__, nil, name: :"#{__MODULE__}_#{suffix}_#{count}")

  @spec get_all_orders(Type.item_name(), Type.server()) :: Type.get_all_orders_response()
  def get_all_orders(item_name, server \\ __MODULE__),
    do: GenServer.call(server, {:get_all_orders, item_name}, @genserver_timeout)

  @spec place_order(Order.t(), Type.server()) :: Type.place_order_response()
  def place_order(order, server \\ __MODULE__),
    do: GenServer.call(server, {:place_order, order}, @genserver_timeout)

  @spec delete_order(PlacedOrder.t(), Type.server()) :: Type.delete_order_response()
  def delete_order(placed_order, server \\ __MODULE__),
    do: GenServer.call(server, {:delete_order, placed_order}, @genserver_timeout)

  @spec login(Credentials.t(), Type.server()) :: Type.login_response()
  def login(credentials, server \\ __MODULE__),
    do: GenServer.call(server, {:login, credentials}, @genserver_timeout)

  @spec recover_login(Authorization.t(), User.t(), Type.server()) :: Type.recover_login_response()
  def recover_login(auth, user, server \\ __MODULE__),
    do: GenServer.call(server, {:recover_login, auth, user}, @genserver_timeout)

  @spec logout(Type.server()) :: Type.logout_response()
  def logout(server \\ __MODULE__), do: GenServer.call(server, :logout, @genserver_timeout)

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

  def handle_call({:delete_order, placed_order}, _from, state),
    do: {:reply, HTTPClient.delete_order(placed_order, state), state}

  def handle_call({:get_all_orders, item_name}, _from, state),
    do: {:reply, HTTPClient.get_all_orders(item_name, state), state}

  def handle_call(
        {:login, credentials},
        _from,
        state
      ) do
    case HTTPClient.login(credentials, state) do
      {:ok, {%Authorization{} = authorization, %User{} = user}} = response ->
        updated_state =
          state
          |> Map.put(:authorization, authorization)
          |> Map.put(:user, user)

        {:reply, response, updated_state}

      error ->
        # in case we have successfully logged in the past, but failed now
        updated_state =
          state
          |> Map.put(:authorization, nil)
          |> Map.put(:user, nil)

        {:reply, error, updated_state}
    end
  end

  def handle_call({:recover_login, auth, user}, _from, state) do
    updated_state =
      state
      |> Map.put(:authorization, auth)
      |> Map.put(:user, user)

    {:reply, :ok, updated_state}
  end

  def handle_call(:logout, _from, state) do
    updated_state =
      state
      |> Map.put(:authorization, nil)
      |> Map.put(:user, nil)

    {:reply, :ok, updated_state}
  end

  @impl GenServer
  @spec terminate(atom, any) :: any
  def terminate(_reason, %{dependencies: %{requests_queue: queue, delete_queue_fn: delete_queue}}),
    do: delete_queue.(queue)

  # If a process leaves normally, we ignore it.
  @impl GenServer
  def handle_info({:EXIT, _pid, :normal}, state), do: {:noreply, state}

  def child_spec(args), do: %{id: __MODULE__, start: {__MODULE__, :start_link, args}}
end
