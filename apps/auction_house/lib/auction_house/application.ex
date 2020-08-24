defmodule AuctionHouse.Application do
  @moduledoc false

  use Application

  alias AuctionHouse.{MockMarketServer, Settings}
  alias Plug.Cowboy

  @requests_per_second 2

  ##########
  # Public #
  ##########

  @spec start(any, nil | maybe_improper_list | map) :: {:error, any} | {:ok, pid}
  def start(_type, args) do
    children = children(args[:env])

    :jobs.add_queue(Settings.requests_queue(), [{:standard_rate, @requests_per_second}])

    opts = [strategy: :one_for_one, name: AuctionHouse.Supervisor]
    Supervisor.start_link(children, opts)
  end

  ###########
  # Private #
  ###########

  @spec children(environment :: atom) :: [{module, keyword}]
  defp children(:test),
    do: [{Cowboy, scheme: :http, plug: MockMarketServer, options: [port: 8082]}]

  defp children(_), do: []

end
