defmodule WebInterface.Live.Window.Main.Activate do
  @moduledoc """
  LiveView subcomponent for the Activate page as part of the Main subcomponent.
  This subcomponent has the options to activate a syndicate given a strategy.

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
        <form phx-change="activate-filters">
          <div class="strategies">
            <div>
              <h3>Strategies</h3>
              <p>Strategies will automatically calculate the prices for your items. If a price's item cannot be calculated, a default one will be used instead.</p>
            </div>
            <div>
              <%= for strat <- @strategies  do %>
                <%= strategy_radio_button(strat: strat, checked: strat == @selected_strategy) %>
              <% end %>
            </div>
          </div>
          <div class="syndicates">
            <div class="intro">
              <h3>Syndicates</h3>
              <p>The syndicates from the game. Only the ones that have items capable of being traded between players are shown.</p>
            </div>
            <div class="checkboxes">
                <input type="hidden" name="syndicates[]" value="">
                <%= for synd <- @syndicates  do %>
                  <%= syndicate_checkbox(synd: synd, checked: synd in @syndicates_to_activate) %>
                <% end %>
            </div>
          </div>
        </form>
        <button
          phx-click="execute_command"
          phx-value-command={@selected_command.id}
          phx-value-strategy={@selected_strategy.id}
          phx-value-syndicates={syndicates_to_string(@syndicates_to_activate)}>
            Execute Command
        </button>
      </div>
    </div>
    """
  end

  defp display_class(:activate), do: "show"
  defp display_class(_), do: "hidden"

  defp syndicates_to_string(syndicates), do:
    Enum.map_join(syndicates, ";", &Syndicates.get_id/1)

  defp syndicate_checkbox(assigns) do
    assigns = Enum.into(assigns, %{})

    if Map.get(assigns, :checked) do
      ~H"""
      <div class="row single-syndicate">
        <input class="column single-checkbox" type="checkbox" id={@synd.id}
                name="syndicates[]" value={@synd.id} checked>

        <label for={@synd.id} class="column"><%= @synd.name %></label>
      </div>
    """
    else
      ~H"""
      <div class="row single-syndicate">
        <input class="column single-checkbox" type="checkbox" id={@synd.id}
                name="syndicates[]" value={@synd.id}>

        <label for={@synd.id} class="column"><%= @synd.name %></label>
      </div>
    """
    end
  end

  defp strategy_radio_button(assigns) do
    assigns = Enum.into(assigns, %{})

    ~L"""
    <div class="radio-button row">
      <div class="choice column column-25">
        <input type="radio" id="<%= @strat.id %>"
                name="strategy" value="<%= @strat.id %>"
                <%= if @checked, do: "checked" %> />
        <label for="<%= @strat.id %>"><%= @strat.name %></label>
      </div>
      <div class="description column">
        <p><%= @strat.description %></p>
      </div>
    </div>
    """
  end

end
