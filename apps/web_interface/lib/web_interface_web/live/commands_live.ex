defmodule WebInterfaceWeb.CommandsLive do
  use WebInterfaceWeb, :live_view

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
    <h1>Actions</1>
    <div id="servers">
      <div class="sidebar">
        <nav>
          <%= for command <- @commands do %>
            <a href="#"
              class="<%= if command == @selected_command, do: 'active' %>">
              <%= command.name %>
            </a>
          <% end %>
        </nav>
      </div>
      <div class="main">
        <div class="wrapper">
          <div class="card">
            Stuff goes in here
          </div>
        </div>
      </div>
    </div>
    """
  end

end
