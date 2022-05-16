defmodule WebInterface.Live.Window.Main.Activate do
  @moduledoc """
  LiveView subcomponent for the Activate page as part of the Main subcomponent.
  This subcomponent has the options to activate a syndicate given a strategy.

  Sends messages back to the `windows` component.
  """

  use WebInterface, :live_component

  alias Elixir.Phoenix.LiveView.Rendered
  alias WebInterface.{Commands, Syndicates}

  @syndicates_total_number 7

  @spec render(map) :: Rendered.t()
  def render(assigns) do
    ~H"""
    <div class={@selected_command.id |> activate?() |> display()}>
      <div class="header">
        <h2>Description</h2>
        <p><%= @selected_command.description %></p>
      </div>
      <div class="body">

        <div class={@active_syndicates |> all_active?() |> display()}>
          <p class="nothing-to-see">All syndicates are active!</p>
        </div>

        <div class={@active_syndicates |> any_deactive?() |> display()}>
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
                  <%= for synd <- inactive_syndicates(@active_syndicates, @syndicates)  do %>
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
    </div>
    """
  end

  @spec inactive_syndicates([Syndicates.syndicate_info()], [Syndicates.syndicate_info()]) :: [
          Syndicates.syndicate_info()
        ]
  defp inactive_syndicates(active_syndicates, all_syndicates),
    do: all_syndicates -- active_syndicates

  @spec activate?(Commands.command_id()) :: boolean()
  defp activate?(:activate), do: true
  defp activate?(_), do: false

  @spec display(boolean) :: String.t()
  defp display(true), do: "show"
  defp display(_), do: "hidden"

  @spec all_active?([Syndicates.syndicate_info()]) :: boolean
  defp all_active?(syndicates) when length(syndicates) == @syndicates_total_number, do: true
  defp all_active?(_syndicates), do: false

  @spec any_deactive?([Syndicates.syndicate_info()]) :: boolean
  defp any_deactive?(syndicates) when length(syndicates) < @syndicates_total_number, do: true
  defp any_deactive?(_syndicates), do: false

  @spec syndicates_to_string([Syndicates.syndicate_info()]) :: String.t()
  defp syndicates_to_string(syndicates), do: Enum.map_join(syndicates, ";", &Syndicates.get_id/1)

  @spec syndicate_checkbox(keyword(any)) :: Rendered.t()
  defp syndicate_checkbox(assigns) do
    assigns = Enum.into(assigns, %{})

    ~H"""
      <div class="row single-syndicate">
        <input class="column single-checkbox" type="checkbox" id={checkbox_id(@synd)} name="syndicates[]" value={@synd.id} checked={@checked}>
        <label for={checkbox_id(@synd)} class="column"><%= @synd.name %></label>
      </div>
    """
  end

  @spec strategy_radio_button(keyword(any)) :: Rendered.t()
  defp strategy_radio_button(assigns) do
    assigns = Enum.into(assigns, %{})

    ~H"""
    <div class="radio-button row">
      <div class="choice column column-25">
        <input type="radio" id={@strat.id} name="strategy" value={@strat.id} checked={@checked}/>
        <label for={@strat.id}><%= @strat.name %></label>
      </div>
      <div class="description column">
        <p><%= @strat.description %></p>
      </div>
    </div>
    """
  end

  @spec checkbox_id(Syndicates.syndicate_info()) :: String.t()
  defp checkbox_id(syndicate), do: "activate:#{syndicate.id}"
end
