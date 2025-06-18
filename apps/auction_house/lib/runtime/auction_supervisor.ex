defmodule AuctionHouse.Runtime.AuctionSupervisor do
  @moduledoc """
  Supervisor of the AuctionHouse application that supervises both the RateLimiter and the Server.
  """

  use Supervisor

  alias RateLimiter

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
      {Task.Supervisor, name: RateLimiter.TaskSupervisor},
      {RateLimiter.get_rate_limiter(), %{requests_per_second: RateLimiter.get_requests_per_second()}},
      AuctionHouse.Runtime.Server
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  def child_spec(_), do: %{id: __MODULE__, start: {__MODULE__, :start_link, []}}
end
