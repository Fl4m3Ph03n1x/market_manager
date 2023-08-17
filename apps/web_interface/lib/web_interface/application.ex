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

  alias Shared.Data.{Strategy, Syndicate}

  @landing_page "/login"

  @strategies [
    Strategy.new(
      name: "Top 3 Average",
      id: :top_three_average,
      description: "Gets the 3 lowest prices for the given item and calculates the average."
    ),
    Strategy.new(
      name: "Top 5 Average",
      id: :top_five_average,
      description: "Gets the 5 lowest prices for the given item and calculates the average."
    ),
    Strategy.new(
      name: "Equal to lowest",
      id: :equal_to_lowest,
      description: "Gets the lowest price for the given item and uses it."
    ),
    Strategy.new(
      name: "Lowest minus one",
      id: :lowest_minus_one,
      description: "Gets the lowest price for the given item and beats it by 1."
    )
  ]

  @syndicates [
    Syndicate.new(name: "Red Veil", id: :red_veil),
    Syndicate.new(name: "Perrin Sequence", id: :perrin_sequence),
    Syndicate.new(name: "New Loka", id: :new_loka),
    Syndicate.new(name: "Arbiters of Hexis", id: :arbiters_of_hexis),
    Syndicate.new(name: "Steel Meridian", id: :steel_meridian),
    Syndicate.new(name: "Cephalon Suda", id: :cephalon_suda),
    Syndicate.new(name: "Cephalon Simaris", id: :cephalon_simaris),
    Syndicate.new(name: "Arbitrations", id: :arbitrations)
  ]

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
          url: fn -> "#{WebInterface.Endpoint.url()}#{@landing_page}" end
        ]]},
        restart: :transient,
        shutdown: 5_000
      }
    ]

    :ok = Persistence.init(@strategies, @syndicates)

    opts = [strategy: :one_for_one, name: WebInterface.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    WebInterface.Endpoint.config_change(changed, removed)
    :ok
  end
end
