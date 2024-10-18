defmodule Manager.Runtime.SagaSupervisor do
  use DynamicSupervisor

  alias Manager.Saga.{Activate, Deactivate, Login}
  alias Shared.Data.{Credentials, Strategy, Syndicate}

  ##############
  # Public API #
  ##############

  def start_link(_init_arg),
    do: DynamicSupervisor.start_link(__MODULE__, nil, name: __MODULE__)

  @spec login(Credentials.t(), keep_logged_in :: boolean) :: :ok
  def login(credentials, keep_logged_in) do
    {:ok, _child} =
      DynamicSupervisor.start_child(
        __MODULE__,
        {Login, %{from: self(), args: %{credentials: credentials, keep_logged_in: keep_logged_in}}}
      )

    :ok
  end

  @spec activate([Syndicate.t()], Strategy.t()) :: :ok
  def activate(syndicates, strategy) when is_list(syndicates) do
    {:ok, _child} =
      DynamicSupervisor.start_child(
        __MODULE__,
        {Activate, %{from: self(), args: %{syndicates: syndicates, strategy: strategy}}}
      )

    :ok
  end

  @spec deactivate([Syndicate.t()]) :: :ok
  def deactivate(syndicates) when is_list(syndicates) do
    {:ok, _child} =
      DynamicSupervisor.start_child(
        __MODULE__,
        {Deactivate, %{from: self(), args: %{syndicates: syndicates}}}
      )

    :ok
  end

  ##############
  # Callbacks  #
  ##############

  @impl DynamicSupervisor
  def init(_init_arg), do: DynamicSupervisor.init(strategy: :one_for_one)
end
