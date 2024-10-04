defmodule Manager.Runtime.TaskSupervisor do
  use DynamicSupervisor

  alias Manager.Type
  alias Manager.UseCase.Login
  alias Shared.Data.Credentials

  ##############
  # Public API #
  ##############

  def start_link(_init_arg),
    do: DynamicSupervisor.start_link(__MODULE__, nil, name: __MODULE__)

  @spec login(Credentials.t(), keep_logged_in :: boolean) :: :ok
  def login(credentials, keep_logged_in) do
    {:ok, child} =
      DynamicSupervisor.start_child(
        __MODULE__,
        {Login,
         %{from: self(), args: %{credentials: credentials, keep_logged_in: keep_logged_in}}}
      )

    :ok
  end

  ##############
  # Callbacks  #
  ##############

  @impl DynamicSupervisor
  def init(_init_arg), do: DynamicSupervisor.init(strategy: :one_for_one)
end
