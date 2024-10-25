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
        {Login,
         %{from: self(), args: %{credentials: credentials, keep_logged_in: keep_logged_in}}}
      )

    :ok
  end

  @spec activate(%{Syndicate.id() => Strategy.t()}, pid() | nil) :: :ok
  def activate(syndicates_with_strategy, from \\ nil)
      when is_map(syndicates_with_strategy) and syndicates_with_strategy != %{} do
    updated_from = from || self()

    {:ok, _child} =
      DynamicSupervisor.start_child(
        __MODULE__,
        {Activate,
         %{from: updated_from, args: %{syndicates_with_strategy: syndicates_with_strategy}}}
      )

    :ok
  end

  @spec deactivate([Syndicate.id()]) :: :ok
  def deactivate(syndicate_ids) when is_list(syndicate_ids) and syndicate_ids != [] do
    {:ok, _child} =
      DynamicSupervisor.start_child(
        __MODULE__,
        {Deactivate, %{from: self(), args: %{syndicate_ids: syndicate_ids}}}
      )

    :ok
  end

  ##############
  # Callbacks  #
  ##############

  @impl DynamicSupervisor
  def init(_init_arg), do: DynamicSupervisor.init(strategy: :one_for_one)
end
