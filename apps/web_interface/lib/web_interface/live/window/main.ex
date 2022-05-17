defmodule WebInterface.Live.Window.Main do
  @moduledoc """
  LiveView subcomponent for the Main Page. It is next to the sidebar and it
  renders a description of what the action is plus it have the options to and
  the button to perform said action.

  Sends messages back to the `windows` component.
  """

  use WebInterface, :live_component

  alias Elixir.Phoenix.LiveView.Rendered
  alias WebInterface.Live.Window.Main.{Activate, Authenticate, Deactivate}

  @spec render(map) :: Rendered.t()
  def render(assigns) do
    ~H"""
    <div class={display(@operation_in_progress)}>
      <%= live_component(Authenticate, [
        selected_command: @selected_command
      ], id: 3271) %>
      <%= live_component(Activate, [
        selected_command: @selected_command,
        selected_strategy: @selected_strategy,
        strategies: @strategies,
        syndicates: @syndicates,
        syndicates_to_activate: @syndicates_to_activate,
        active_syndicates: @active_syndicates
      ], id: 823) %>
      <%= live_component(Deactivate, [
        selected_command: @selected_command,
        syndicates: @syndicates,
        syndicates_to_deactivate: @syndicates_to_deactivate,
        active_syndicates: @active_syndicates
      ], id: 2671) %>
    </div>
    """
  end

  @spec display(boolean()) :: String.t()
  defp display(true), do: "hidden"
  defp display(_), do: "main column column-80 show"
end
