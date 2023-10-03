defmodule WebInterface.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  alias Desktop
  alias ETS
  alias Manager
  alias WebInterface.{Endpoint, PubSub, Telemetry}
  alias WebInterface.Desktop.{MenuBar, WindowUtils}
  alias WebInterface.Persistence
  alias WebInterface.Persistence.Syndicate, as: SyndicateStore

  @impl true
  def start(_type, _args) do
    children = [
      Telemetry,
      {Phoenix.PubSub, name: PubSub},
      Endpoint,
      Manager,
      %{
        id: Desktop.Window,
        start: {Desktop.Window, :start_link, [[
          app: :web_interface,
          id: WebInterface,
          title: "Market Manager",
          size: WindowUtils.calculate_window_size(0.6, 0.8),
          menubar: MenuBar,
          icon: "static/images/resized_logo_5_32x32.png",
          url: fn -> "#{WebInterface.Endpoint.url()}/" end
        ]]},
        restart: :transient,
        shutdown: 5_000
      }
    ]
    opts = [strategy: :one_for_one, name: WebInterface.Supervisor]

    with  {:ok, _pid} = link <- Supervisor.start_link(children, opts),
          {:ok, syndicates} <- Manager.syndicates(),
          {:ok, strategies} <- Manager.strategies(),
          {:ok, user} <- Manager.recover_login(),
          :ok <- Persistence.init(strategies, syndicates, user),
          :ok <- SyndicateStore.set_selected_inactive_syndicates(syndicates) do
            link
    end
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    WebInterface.Endpoint.config_change(changed, removed)
    :ok
  end
end
