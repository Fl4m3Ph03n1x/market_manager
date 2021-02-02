defmodule WebInterfaceWeb.LightLiveTest do
  use WebInterfaceWeb.ConnCase

  import Phoenix.LiveViewTest

  test "disconnected and connected render", %{conn: conn} do
    {:ok, page_live, disconnected_html} = live(conn, "/")
    assert disconnected_html =~ "On"
    assert render(page_live) =~ "On"
  end
end
