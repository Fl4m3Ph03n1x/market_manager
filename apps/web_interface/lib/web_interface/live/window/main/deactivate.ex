defmodule WebInterface.Live.Window.Main.Deactivate do
  @moduledoc """
  LiveView subcomponent for the Deactivate page as part of the Main subcomponent.
  This subcomponent has the options to deactivate a previously activated syndicate.

  Sends messages back to the `windows` component.
  """

  use WebInterface, :live_component

  alias Elixir.Phoenix.LiveView.Rendered
  alias WebInterface.Syndicates

  @spec render(map) :: Rendered.t
  def render(assigns) do
    ~H"""
    <div class={display_class(@selected_command.id)}>
      <div class="header">
        <h2>Description</h2>
        <p><%= @selected_command.description %></p>
      </div>
      <div class="body">
        <form phx-change="filters">
          <div class="syndicates">
            <div class="intro">
              <h3>Syndicates</h3>
              <p>The syndicates from the game. Only the ones that have items capable of being traded between players are shown.</p>
            </div>
            <div class="checkboxes">
                <input type="hidden" name="syndicates[]" value="">
                <%= for synd <- @syndicates  do %>
                  <%= syndicate_checkbox(synd: synd, checked: synd in @selected_syndicates) %>
                <% end %>
            </div>
          </div>
        </form>
        <button
          phx-click="execute_command"
          phx-value-command={@selected_command.id}
          phx-value-strategy={@selected_strategy.id}
          phx-value-syndicates={selected_syndicates_to_string(@selected_syndicates)}>
            Execute Command
        </button>
      </div>
    </div>
    """
  end

  defp display_class(:deactivate), do: "show"
  defp display_class(_), do: "hidden"

  defp selected_syndicates_to_string(syndicates), do:
    Enum.map_join(syndicates, ";", &Syndicates.get_id/1)

  defp syndicate_checkbox(assigns) do
    assigns = Enum.into(assigns, %{})

    ~L"""
      <div class="row single-syndicate">
        <input class="column single-checkbox" type="checkbox" id="<%= @synd.id %>"
                name="syndicates[]" value="<%= @synd.id %>"
                <%= if @checked, do: "checked" %>>

        <label for="<%= @synd.id %>" class="column"><%= @synd.name %></label>
      </div>
    """
  end

end
