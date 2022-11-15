defmodule WebInterface.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  alias Desktop
  alias Manager
  alias WebInterface.{Endpoint, Telemetry}
  alias WebInterface.Live.MenuBar

  @impl true
  def start(_type, _args) do
    children = [
      Telemetry,
      {Phoenix.PubSub, name: WebInterface.PubSub},
      Endpoint,
      Manager,
      {Desktop.Window,
       [
         app: :web_interface,
         id: WebInterface,
         title: "Market Manager",
         size: {940, 980},
         menubar: MenuBar,
         icon: "static/images/resized_logo_5_32x32.png",
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
