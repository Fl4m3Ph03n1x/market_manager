defmodule WebInterface.Live.MenuBar do
  @moduledoc """
  Menubar that is shown as part of the main Window on Windows/Linux. In
  MacOS this Menubar appears at the very top of the screen.
  """

  use Desktop.Menu

  alias Desktop.Window

  @impl Desktop.Menu
  def render(assigns) do
    ~H"""
    <menubar>
      <menu label="File">
          <hr/>
          <item onclick="quit">Quit</item>
      </menu>
      <menu label="Extra">
          <item onclick="browser">Open Browser</item>
      </menu>
    </menubar>
    """
  end

  @impl Desktop.Menu
  def handle_event("quit", menu) do
    Window.quit()
    {:noreply, menu}
  end

  def handle_event("browser", menu) do
    WebInterface.Endpoint.url()
    |> Window.prepare_url()
    |> :wx_misc.launchDefaultBrowser()

    {:noreply, menu}
  end

  @impl Desktop.Menu
  def mount(menu) do
    {:ok, menu}
  end

  @impl Desktop.Menu
  def handle_info(:changed, menu) do
    {:noreply, menu}
  end
end
