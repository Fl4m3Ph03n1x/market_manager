defmodule AuctionHouse.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  @outgoing_requests_queue :outgoing_requests_queue

  use Application

  def start(_type, _args) do
    children = [
      # Starts a worker by calling: AuctionHouse.Worker.start_link(arg)
      # {AuctionHouse.Worker, arg}
    ]

    :jobs.add_queue(@outgoing_requests_queue, [{:standard_rate, 10}])

    opts = [strategy: :one_for_one, name: AuctionHouse.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
