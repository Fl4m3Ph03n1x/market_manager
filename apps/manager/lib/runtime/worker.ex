defmodule Manager.Runtime.Worker do
  use GenServer

  alias Manager.Impl.Interpreter
  alias Manager.Type

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

  @spec activate(Type.syndicate(), Type.strategy()) :: :ok
  def activate(syndicate, strategy),
    do: GenServer.cast(__MODULE__, {:activate, syndicate, strategy, self()})

  @spec deactivate(Type.syndicate()) :: :ok
  def deactivate(syndicate), do: GenServer.cast(__MODULE__, {:deactivate, syndicate, self()})

  ##############
  # Callbacks  #
  ##############

  @impl GenServer
  @spec init(state) :: {:ok, state}
  def init(deps), do: {:ok, deps}

  @impl GenServer
  @spec handle_cast(request :: any, state) :: {:noreply, state}
  def handle_cast({:activate, syndicate, strategy, from_pid}, deps) do
    deps[:interpreter].activate(syndicate, strategy, fn result ->
      send(from_pid, result)
    end)

    {:noreply, deps}
  end

  def handle_cast({:deactivate, syndicate, from_pid}, deps) do
    deps[:interpreter].deactivate(syndicate, fn result ->
      send(from_pid, result)
    end)

    {:noreply, deps}
  end
end