defmodule AuctionHouse.Runtime.Server do
  @moduledoc """
  Process responsible for managing requests to the auction house.
  Talks to the logic layer and terminates gracefully.
  """

  use GenServer

  require Logger

  alias AuctionHouse.Type
  alias Shared.Data.{Authorization, Credentials, Order, PlacedOrder, User}
  alias AuctionHouse.Impl.UseCase.{DeleteOrder, GetItemOrders, GetUserOrders, Login, PlaceOrder}
  alias AuctionHouse.Impl.UseCase.Data.{Metadata, Request}

  ##############
  # Public API #
  ##############

  @spec start_link :: :ignore | {:error, any} | {:ok, pid}
  def start_link, do: GenServer.start_link(__MODULE__, nil, name: __MODULE__)

  @spec get_item_orders(Type.item_name()) :: :ok
  def get_item_orders(item_name),
    do: GenServer.cast(__MODULE__, {:get_item_orders, item_name, self()})

  @spec get_user_orders(Type.username()) :: :ok
  def get_user_orders(username),
    do: GenServer.cast(__MODULE__, {:get_user_orders, username, self()})

  @spec place_order(Order.t()) :: :ok
  def place_order(order), do: GenServer.cast(__MODULE__, {:place_order, order, self()})

  @spec delete_order(PlacedOrder.t()) :: :ok
  def delete_order(placed_order),
    do: GenServer.cast(__MODULE__, {:delete_order, placed_order, self()})

  @spec login(Credentials.t()) :: :ok
  def login(credentials), do: GenServer.cast(__MODULE__, {:login, credentials, self()})

  @spec update_login(Authorization.t(), User.t()) :: Type.recover_login_response()
  def update_login(auth, user),
    do: GenServer.call(__MODULE__, {:update_login, auth, user})

  @spec logout :: Type.logout_response()
  def logout, do: GenServer.call(__MODULE__, :logout)

  #############
  # Callbacks #
  #############

  @impl GenServer
  @spec init(nil) :: {:ok, Type.state()}
  def init(nil) do
    Process.flag(:trap_exit, true)
    {:ok, %{user: nil, authorization: nil}}
  end

  @impl GenServer
  def handle_cast({:place_order, order, from}, state) do
    PlaceOrder.start(%{
      from: [from],
      operation: :place_order,
      order: order,
      authorization: state.authorization,
      send?: false
    })

    {:noreply, state}
  end

  def handle_cast({:delete_order, placed_order, from}, state) do
    DeleteOrder.start(%{
      from: [from],
      operation: :delete_order,
      placed_order: placed_order,
      authorization: state.authorization,
      send?: false
    })

    {:noreply, state}
  end

  def handle_cast({:get_item_orders, item_name, from}, state) do
    GetItemOrders.start(%{
      from: [from],
      operation: :get_item_orders,
      item_name: item_name,
      send?: false
    })

    {:noreply, state}
  end

  def handle_cast({:get_user_orders, username, from}, state) do
    GetUserOrders.start(%{
      from: [from],
      operation: :get_user_orders,
      username: username,
      send?: false
    })

    {:noreply, state}
  end

  def handle_cast({:login, credentials, from}, state) do
    :login
    |> Metadata.new([from, self()])
    |> Request.new(%{credentials: credentials})
    |> Login.start()

    {:noreply, state}
  end

  @impl GenServer
  def handle_call({:update_login, auth, user}, _from, state) do
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

  # If a process leaves normally, we ignore it.
  @impl GenServer
  def handle_info({:EXIT, _pid, :normal}, state), do: {:noreply, state}

  def handle_info({:login, {:ok, {authorization, user}}}, state) do
    updated_state =
      state
      |> Map.put(:authorization, authorization)
      |> Map.put(:user, user)

    {:noreply, updated_state}
  end

  def handle_info({:login, _error}, state) do
    # in case we have successfully logged in the past, but failed now
    updated_state =
      state
      |> Map.put(:authorization, nil)
      |> Map.put(:user, nil)

    {:noreply, updated_state}
  end

  def handle_info({_op, {:ok, _response}}, state) do
    {:noreply, state}
  end

  def handle_info({op, {:error, _} = error}, state) do
    Logger.error("Error for operation: #{op} - #{inspect(error)}")
    {:noreply, state}
  end

  def child_spec(args), do: %{id: __MODULE__, start: {__MODULE__, :start_link, args}}
end
