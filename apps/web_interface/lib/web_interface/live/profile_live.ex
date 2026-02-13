defmodule WebInterface.ProfileLive do
  use WebInterface, :live_view

  require Logger

  alias Manager
  alias WebInterface.Persistence.User, as: UserStore

  @impl true
  def mount(_params, _session, socket) do
    case UserStore.get_user() do
      {:ok, user} ->
        {:ok, assign(socket, user: user)}

      error ->
        Logger.error("Unable to show profile page: #{inspect(error)}")
        {:error, socket |> put_flash(:error, "Unable to show profile page!")}
    end
  end
end
