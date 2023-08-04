defmodule WebInterface.Components.OperationProgress do
  @moduledoc """
  LiveView subcomponent for the Operation Progress Page. It hides both sidebar and main
  subcomponents and displays information about operations taking place.

  Sends messages back to the `windows` component.
  """

  use WebInterface, :live_component

  alias Elixir.Phoenix.LiveView.Rendered

  @spec render(map) :: Rendered.t()
  def render(assigns) do
    ~H"""
    <div class={display(@operation_in_progress)}>

      <div class="wrap-circles">
        <p><%= progress_message(@current_syndicate) %></p>

        <div class={circle(@progress_bar_value)}>
          <div class="inner"><%= @progress_bar_value %>%</div>
        </div>
      </div>
    </div>
    """
  end

  @spec display(boolean()) :: String.t()
  defp display(false), do: "hidden"
  defp display(_), do: "main column column-100 show"

  @spec circle(progress :: non_neg_integer()) :: String.t()
  defp circle(progress), do: "circle per-#{progress}"

  @spec progress_message(String.t() | nil) :: String.t()
  defp progress_message(nil), do: "Setting up ..."
  defp progress_message(syndicate), do: "Operation in progress for #{syndicate} ..."
end
