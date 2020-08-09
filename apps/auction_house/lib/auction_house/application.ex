defmodule AuctionHouse.Application do
  @moduledoc false

  @outgoing_requests_queue :outgoing_requests_queue

  use Application

  alias AuctionHouse.MockMarketServer
  alias Plug.Cowboy

  @spec start(any, nil | maybe_improper_list | map) :: {:error, any} | {:ok, pid}
  def start(_type, args) do
    children = children(args[:env])

    :jobs.add_queue(@outgoing_requests_queue, [{:standard_rate, 2}])

    opts = [strategy: :one_for_one, name: AuctionHouse.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @spec children(environment :: atom) :: [{module, keyword}]
  defp children(:test),
    do: [{Cowboy, scheme: :http, plug: MockMarketServer, options: [port: 8082]}]

  defp children(_), do: []

end
