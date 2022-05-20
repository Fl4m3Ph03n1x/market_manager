defmodule WebInterface.Live.Window.Main.Deactivate do
  @moduledoc """
  LiveView subcomponent for the Deactivate page as part of the Main subcomponent.
  This subcomponent has the options to deactivate a previously activated syndicate.

  Sends messages back to the `windows` component.
  """

  use WebInterface, :live_component

  alias Elixir.Phoenix.LiveView.Rendered
  alias WebInterface.{Commands, Syndicates}

  @spec render(map) :: Rendered.t()
  def render(assigns) do
    ~H"""
    <div class={@selected_command.id |> deactivate?() |> display()}>
      <div class="header">
        <h2>Description</h2>
        <p><%= @selected_command.description %></p>
      </div>
      <div class="body">

        <div class={@active_syndicates |> none_active?() |> display()}>
          <p class="nothing-to-see">No syndicates are active right now.</p>
        </div>

        <div class={@active_syndicates |> any_active?() |> display()}>
          <form phx-change="deactivate-filters">
            <div class="syndicates">
              <div class="intro">
                <h3>Syndicates</h3>
                <p>The syndicates from the game. Only the ones that have items capable of being traded between players and are active right now are shown.</p>
              </div>
              <div class="checkboxes">
                  <input type="hidden" name="syndicates[]" value="">
                  <%= for synd <- @active_syndicates  do %>
                    <%= syndicate_checkbox(synd: synd, checked: synd in @syndicates_to_deactivate) %>
                  <% end %>
              </div>
            </div>
          </form>

          <button
            phx-click="execute_command"
            phx-value-command={@selected_command.id}
            phx-value-syndicates={syndicates_to_string(@syndicates_to_deactivate)}>
              Execute Command
          </button>
        </div>
      </div>
    </div>
    """
  end

  @spec deactivate?(Commands.command_id()) :: boolean
  defp deactivate?(:deactivate), do: true
  defp deactivate?(_), do: false

  @spec display(boolean) :: String.t()
  defp display(true), do: "show"
  defp display(_), do: "hidden"

  @spec any_active?([Syndicates.syndicate_info()]) :: boolean
  defp any_active?([]), do: false
  defp any_active?(_), do: true

  @spec none_active?([Syndicates.syndicate_info()]) :: boolean
  defp none_active?(data), do: !any_active?(data)

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

  @spec checkbox_id(Syndicates.syndicate_info()) :: String.t()
  defp checkbox_id(syndicate), do: "deactivate:#{syndicate.id}"
end
