defmodule WebInterface.Live.Window.Sidebar do
  @moduledoc """
  LiveView subcomponent for the sidebar of the UI. The sidebar is basically a
  menu that has all the actions the user is able to perform.

  Upon picking an action, the page on `main` subcomponent is then rendered
  accordingly.
  """

  use WebInterface, :live_component

  alias Elixir.Phoenix.LiveView.Rendered
  alias WebInterface.Commands

  @spec render(map) :: Rendered.t
  def render(assigns) do
    ~H"""
    <div class="sidebar column">
      <nav class="nav">
        <%= for command <- @commands do %>

            <a href="#"
              phx-click="show"
              phx-value-id={command.id}
              class={command_class(command, @selected_command)}>
              <div class="sidebar-button"><%= command.name %></div>
            </a>

        <% end %>
      </nav>
    </div>
    """
  end

  @spec command_class(Commands.command, Commands.command) :: String.t
  defp command_class(command, selected), do: active?(command == selected)

  @spec active?(bool) :: String.t
  defp active?(true = _active?), do: "active"
  defp active?(_active?), do: ""

end
