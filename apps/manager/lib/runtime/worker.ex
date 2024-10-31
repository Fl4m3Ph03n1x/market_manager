defmodule Manager.Runtime.Worker do
  @moduledoc """
  Process responsible for doing asynchronous tasks. The Worker is supervised by the `Server` and is
  restarted should something fail. It communicates with the calling client via `send/2`, since we
  don't know if the client is a `GenServer` or not. Should this change (and we are sure the client
  is a `GenServer`) then `GenServer.cast` should be used instead.
  """

  use GenServer

  alias Manager.Type
  alias Manager.Impl.PriceAnalyst

  @opaque state :: [
            store: module(),
            auction_house: module()
          ]

  ##############
  # Public API #
  ##############

  @spec start_link(state) :: GenServer.on_start()
  def start_link(deps), do: GenServer.start_link(__MODULE__, deps, name: __MODULE__)

  @spec recover_login :: Type.recover_login_response()
  def recover_login, do: GenServer.call(__MODULE__, :recover_login)

  @spec logout :: Type.logout_response()
  def logout, do: GenServer.call(__MODULE__, :logout)

  @spec syndicates :: Type.syndicates_response()
  def syndicates, do: GenServer.call(__MODULE__, :syndicates)

  @spec active_syndicates :: Type.active_syndicates_response()
  def active_syndicates, do: GenServer.call(__MODULE__, :active_syndicates)

  @spec strategies :: Type.strategies_response()
  def strategies, do: GenServer.call(__MODULE__, :strategies)

  ##############
  # Callbacks  #
  ##############

  @impl GenServer
  @spec init(state) :: {:ok, state}
  def init(deps), do: {:ok, deps}

  @impl GenServer
  @spec handle_call(request :: any, GenServer.from(), state) :: {:reply, response :: any, state}
  def handle_call(:recover_login, _from, [store: store, auction_house: _auction_house] = state) do
    case store.get_login_data() do
      {:ok, {_auth, user}} ->
        {:reply, {:ok, user}, state}

      response ->
        {:reply, response, state}
    end
  end

  def handle_call(:logout, _from, [store: store, auction_house: auction_house] = state) do
    with :ok <- auction_house.logout(),
         :ok <- store.delete_login_data() do
      {:reply, :ok, state}
    end
  end

  def handle_call(:syndicates, _from, [store: store, auction_house: _auction_house] = state) do
    {:reply, store.list_syndicates(), state}
  end

  def handle_call(
        :active_syndicates,
        _from,
        [store: store, auction_house: _auction_house] = state
      ) do
    {:reply, store.list_active_syndicates(), state}
  end

  def handle_call(:strategies, _from, state) do
    {:reply, PriceAnalyst.list_strategies(), state}
  end
end
