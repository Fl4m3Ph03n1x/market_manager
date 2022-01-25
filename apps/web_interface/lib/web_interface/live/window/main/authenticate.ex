defmodule WebInterface.Live.Window.Main.Authenticate do
  @moduledoc """
  LiveView subcomponent for the Authenticate page as part of the Main subcomponent.
  This subcomponent has the forms for the user's authentication.

  Sends messages back to the `windows` component.
  """

  use WebInterface, :live_component

  alias Elixir.Phoenix.LiveView.Rendered

  @spec render(map) :: Rendered.t
  def render(assigns) do
    ~H"""
    <div class={display_class(@selected_command.id)}>
      <div class="header">
        <h2>Description</h2>
        <p><%= @selected_command.description %></p>
      </div>
      <div class="body">

        <form phx-submit="authenticate">
          <div class="intro">
            <h3>Authentication</h3>
            <p>
              Fill the Cookie and token.
              This information expires from time to time and it is normal if you need to fill these forms again in the future.
            </p>
          </div>
          <label for="cookie">Cookie: </label>
          <textarea id="cookie" name="cookie"/>

          <label for="token">Token: </label>
          <textarea id="token" name="token"/>

          <button type="submit">Save</button>
        </form>

      </div>
    </div>
    """
  end

  defp display_class(:authenticate), do: "show"
  defp display_class(_), do: "hidden"

end
