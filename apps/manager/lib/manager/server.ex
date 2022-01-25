defmodule Manager.Server do
  @moduledoc """
  Process responsible for taking requests from the interface and directing them
  to the appropriate layers. Supervises dependencies to make sure they are
  regenerated should something fail.
  """

  use Supervisor

  alias AuctionHouse
  alias Store

  ##############
  # Public API #
  ##############

  @spec start_link(any) :: :ignore | {:error, any} | {:ok, pid}
  def start_link(_args), do:
    Supervisor.start_link(__MODULE__, nil, name: __MODULE__)

  ##############
  # Callbacks  #
  ##############

  @impl Supervisor
  @spec init(nil) :: {:ok, {:supervisor.sup_flags, [:supervisor.child_spec]}} | :ignore
  def init(nil) do
    credentials = Store.get_credentials()

    children = [
      {AuctionHouse, credentials}
    ]
    Supervisor.init(children, strategy: :one_for_one)
  end
end
