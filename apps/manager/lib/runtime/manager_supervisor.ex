defmodule Manager.Runtime.ManagerSupervisor do
  @moduledoc """
  Process responsible for taking requests from the interface and directing them
  to the appropriate layers. Supervises dependencies to make sure they are
  regenerated should something fail.
  """

  use Supervisor

  alias AuctionHouse
  alias Manager.Runtime.{SagaSupervisor, Worker}
  alias Store

  ##############
  # Public API #
  ##############

  @spec start_link :: :ignore | {:error, any} | {:ok, pid}
  def start_link, do: Supervisor.start_link(__MODULE__, nil, name: __MODULE__)

  ##############
  # Callbacks  #
  ##############

  @impl Supervisor
  @spec init(nil) :: {:ok, {:supervisor.sup_flags(), [:supervisor.child_spec()]}} | :ignore
  def init(nil) do
    children = [
      AuctionHouse,
      {Worker, [store: Store, auction_house: AuctionHouse]},
      SagaSupervisor
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  def child_spec(_), do: %{id: __MODULE__, start: {__MODULE__, :start_link, []}}
end
