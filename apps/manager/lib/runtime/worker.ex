defmodule Manager.Runtime.Worker do
  @moduledoc """
  Process responsible for doing asynchronous tasks. The Worker is supervised by the `Server` and is
  restarted should something fail. It communicates with the calling client via `send/2`, since we
  don't know if the client is a `GenServer` or not. Should this change (and we are sure the client
  is a `GenServer`) then `GenServer.cast` should be used instead.
  """

  use GenServer

  alias Manager.Impl.Interpreter
  alias Manager.Type
  alias Shared.Data.{Credentials, Strategy, Syndicate}

  @type from :: pid
  @type state :: keyword(module)

  @default_deps [
    interpreter: Interpreter
  ]

  ##############
  # Public API #
  ##############

  @spec start_link(state) :: GenServer.on_start()
  def start_link([]),
    do: GenServer.start_link(__MODULE__, @default_deps, name: __MODULE__)

  def start_link(deps),
    do: GenServer.start_link(__MODULE__, deps, name: __MODULE__)

  @spec activate(Syndicate.t(), Strategy.t()) :: :ok
  def activate(syndicate, strategy),
    do: GenServer.cast(__MODULE__, {:activate, syndicate, strategy, self()})

  @spec deactivate(Syndicate.t()) :: :ok
  def deactivate(syndicate), do: GenServer.cast(__MODULE__, {:deactivate, syndicate, self()})

  @spec login(Credentials.t(), keep_logged_in :: boolean) :: Type.login_response()
  def login(credentials, keep_logged_in),
    do: GenServer.cast(__MODULE__, {:login, {credentials, keep_logged_in}, self()})

  @spec recover_login :: Type.recover_login_response()
  def recover_login, do: GenServer.call(__MODULE__, :recover_login)

  @spec logout :: Type.logout_response()
  def logout, do: GenServer.call(__MODULE__, :logout)

  @spec syndicates :: Type.syndicates_response()
  def syndicates, do: GenServer.call(__MODULE__, :syndicates)

  @spec strategies :: Type.strategies_response()
  def strategies, do: GenServer.call(__MODULE__, :strategies)

  ##############
  # Callbacks  #
  ##############

  @impl GenServer
  @spec init(state) :: {:ok, state}
  def init(deps), do: {:ok, deps}

  @impl GenServer
  @spec handle_cast(request :: any, state) :: {:noreply, state}
  def handle_cast({:activate, syndicate, strategy, from_pid}, [interpreter: interpreter] = deps) do
    interpreter.activate(syndicate, strategy, fn result ->
      send(from_pid, result)
    end)

    {:noreply, deps}
  end

  def handle_cast({:deactivate, syndicate, from_pid}, [interpreter: interpreter] = deps) do
    interpreter.deactivate(syndicate, fn result ->
      send(from_pid, result)
    end)

    {:noreply, deps}
  end

  def handle_cast(
        {:login, {credentials, keep_logged_in}, from_pid},
        [interpreter: interpreter] = deps
      ) do
    interpreter.login(credentials, keep_logged_in, fn result ->
      send(from_pid, result)
    end)

    {:noreply, deps}
  end

  @impl GenServer
  @spec handle_call(request :: any, from, state) :: {:reply, response :: any, state}
  def handle_call(:syndicates, _from, [interpreter: interpreter] = deps) do
    {:reply, interpreter.syndicates(), deps}
  end

  def handle_call(:strategies, _from, [interpreter: interpreter] = deps) do
    {:reply, interpreter.strategies(), deps}
  end

  def handle_call(:recover_login, _from, [interpreter: interpreter] = deps) do
    {:reply, interpreter.recover_login(), deps}
  end

  def handle_call(:logout, _from, [interpreter: interpreter] = deps) do
    {:reply, interpreter.logout(), deps}
  end
end
