defmodule WebInterfaceWeb.CommandsLive do
  use WebInterfaceWeb, :live_view


  require Logger
  alias WebInterface.{Commands, Strategies}


  @impl true
  def mount(_params, _session, socket) do
    commands = Commands.list_commands()
    strategies = Strategies.list_strategies()

    socket = assign(socket,
      commands: commands,
      selected_command: hd(commands),
      strategies: strategies,
      selected_strategy: hd(strategies)
    )

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~L"""
    <h1>Actions</h1>
    <div id="servers">
      <div class="sidebar">
        <nav>
          <%= for command <- @commands do %>
            <a href="#"
              phx-click="show"
              phx-value-id="<%= command.id %>"
              class="<%= if command == @selected_command, do: 'active' %>">
              <%= command.name %>
            </a>
          <% end %>
        </nav>
      </div>
      <div class="main">
        <div class="wrapper">
          <div class="card">
            <div class="header">
              <h2>Description</h2>
              <span><%= @selected_command.description %></span>
            </div>
            <div class="body">
              <div>

                <%= for strat <- @strategies  do %>
                  <%= strategy_radio_button(strat: strat, checked: strat == @selected_strategy) %>
                <% end %>

              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def handle_event("show", %{"id" => id}, socket) do
    command =
      id
      |> String.to_existing_atom()
      |> Commands.get_command()

    socket = assign(socket, selected_command: command)
    {:noreply, socket}
  end

  defp strategy_radio_button(assigns) do
    assigns = Enum.into(assigns, %{})

    ~L"""
    <input type="radio" id="<%= @strat.id %>"
            name="strategy" value="<%= @strat.id %>"
            <%= if @checked, do: "checked" %> />
    <label for="<%= @strat.id %>"><%= @strat.name %></label>
    </br>
    """
  end

end
