defmodule WebInterface.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

    alias Desktop

  @impl true
  def start(_type, _args) do
    children = [
      WebInterface.Telemetry,
      {Phoenix.PubSub, name: WebInterface.PubSub},
      WebInterface.Endpoint,
      {Desktop.Window,
       [
         app: :web_interface,
         id: WebInterface,
         title: "Web Interface",
         size: {600, 500},
         menubar: WebInterface.MenuBar,
         url: &WebInterface.Endpoint.url/0
       ]}
    ]

    opts = [strategy: :one_for_one, name: WebInterface.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @impl true
  def config_change(changed, _new, removed) do
    WebInterface.Endpoint.config_change(changed, removed)
    :ok
  end
end
