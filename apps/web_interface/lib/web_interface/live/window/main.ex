defmodule WebInterface.Live.Window.Main do
  @moduledoc """
  LiveView subcomponent for the Main Page. It is next to the sidebar and it
  renders a description of what the action is plus it have the options to and
  the button to perform said action.

  Sends messages back to the ``windows` component.
  """

  use WebInterface, :live_component

  alias Elixir.Phoenix.LiveView.Rendered
  alias WebInterface.Live.Window.Main.{Activate, Authenticate, Deactivate}

  @spec render(map) :: Rendered.t
  def render(assigns) do
    ~H"""
    <div class="main column column-80">
      <%= live_component(Authenticate, [selected_command: @selected_command], id: 3) %>
      <%= live_component(Activate, [
        selected_command: @selected_command,
        selected_strategy: @selected_strategy,
        selected_syndicates: @selected_syndicates,
        strategies: @strategies,
        syndicates: @syndicates
      ], id: 4) %>
      <%= live_component(Deactivate, [
        selected_command: @selected_command,
        selected_strategy: @selected_strategy,
        selected_syndicates: @selected_syndicates,
        strategies: @strategies,
        syndicates: @syndicates
      ], id: 5) %>
    </div>
    """
  end

end
