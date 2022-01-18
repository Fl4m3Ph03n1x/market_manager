defmodule WebInterface.Live.Window.Main do
  @moduledoc """
  LiveView subcomponent for the Main Page. It is next to the sidebar and it
  renders a description of what the action is plus it have the options to and
  the button to perform said action.

  Sends messages back to the ``windows` component.
  """

  use WebInterface, :live_component

  alias Elixir.Phoenix.LiveView.Rendered
  alias WebInterface.Syndicates

  @spec render(map) :: Rendered.t
  def render(assigns) do
    ~H"""
    <div class="main column column-80">
        <div class="header">
          <h2>Description</h2>
          <p><%= @selected_command.description %></p>
        </div>
        <div class="body">
          <form phx-change="filters">
            <div class={command_class(@selected_command.id)}>
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
            </div>
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

  @spec command_class(atom) :: String.t
  defp command_class(:deactivate = _command_id), do: "hidden"
  defp command_class(_command_id), do: ""

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
