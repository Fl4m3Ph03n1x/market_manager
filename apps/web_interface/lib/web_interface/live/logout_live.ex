defmodule WebInterface.LogoutLive do
  use WebInterface, :live_view

  require Logger

  alias Manager
  alias WebInterface.Persistence.User, as: UserStore

  @impl true
  def mount(_params, _session, socket) do
    with :ok <- Manager.logout(),
         :ok <- UserStore.set_user(nil) do
      socket =
        socket
        |> put_flash(:info, "You logged out successfully!")
        |> redirect(to: ~p"/login")

      {:ok, socket}
    else
      error ->
        Logger.error("Unable to logout correctly due to: #{inspect(error)}")

        socket =
          socket
          |> put_flash(:error, "Unable to logout correctly. Redirecting to Login.")
          |> redirect(to: ~p"/login")

        {:ok, socket}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""

    """
  end
end
