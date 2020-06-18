defmodule MarketManager.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  alias Plug.Cowboy
  alias MarketManager.FakeMarketServer

  def start(_type, args) do
    children =
      case args do
        [env: :integration] ->
          [{Cowboy, scheme: :http, plug: FakeMarketServer, options: [port: 8082]}]

        _ ->
          []
      end

    opts = [strategy: :one_for_one, name: MarketManager.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
