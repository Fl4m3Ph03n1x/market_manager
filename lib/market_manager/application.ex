defmodule MarketManager.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  alias MarketManager.MockMarketServer
  alias Plug.Cowboy

  def start(_type, args) do
    children = children(args[:env])

    opts = [strategy: :one_for_one, name: MarketManager.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp children(:test),
    do: [{Cowboy, scheme: :http, plug: MockMarketServer, options: [port: 8082]}]

  defp children(_), do: []
end
