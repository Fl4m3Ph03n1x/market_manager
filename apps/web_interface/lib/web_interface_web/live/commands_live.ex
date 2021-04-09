defmodule WebInterfaceWeb.CommandsLive do
  use WebInterfaceWeb, :live_view


  require Logger
  alias WebInterface.Commands

  @impl true
  def mount(_params, _session, socket) do
    commands  = Commands.list_commands()
    socket = assign(socket,
      commands: commands,
      selected_command: hd(commands)
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
              phx-value-name="<%= command.name %>"
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

            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def handle_event("show", %{"name" => cname}, socket) do
    command = Commands.get_command(cname)

    socket = assign(socket, selected_command: command)
    {:noreply, socket}
  end

end
