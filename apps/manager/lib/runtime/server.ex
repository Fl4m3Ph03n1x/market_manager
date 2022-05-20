defmodule Manager.Runtime.Server do
  @moduledoc """
  Process responsible for taking requests from the interface and directing them
  to the appropriate layers. Supervises dependencies to make sure they are
  regenerated should something fail.
  """

  use Supervisor

  alias AuctionHouse
  alias Manager.Impl.Interpreter
  alias Manager.Runtime.Worker
  alias Store

  ##############
  # Public API #
  ##############

  @spec start_link(any) :: :ignore | {:error, any} | {:ok, pid}
  def start_link(_args), do: Supervisor.start_link(__MODULE__, nil, name: __MODULE__)

  ##############
  # Callbacks  #
  ##############

  @impl Supervisor
  @spec init(nil) :: {:ok, {:supervisor.sup_flags(), [:supervisor.child_spec()]}} | :ignore
  def init(nil) do
    credentials = credentials_or_default()

    children = [
      {AuctionHouse, credentials},
      {Worker, [interpreter: Interpreter]}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  # If we have no setup.json, we provide some default credentials. The user will have to
  # update them anyway when making the requests, and when he does, we save them correctly.
  @spec credentials_or_default :: Store.Type.get_credentials_response()
  defp credentials_or_default do
    default_credentials = %{"cookie" => "cookie", "token" => "token"}

    case Store.get_credentials() do
      {:error, :enoent} -> {:ok, default_credentials}
      creds -> creds
    end
  end
end
