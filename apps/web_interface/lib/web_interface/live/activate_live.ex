defmodule WebInterface.ActivateLive do
  use WebInterface, :live_view

  require Logger

  alias Manager
  alias Shared.Data.{Credentials, User}
  alias WebInterface.Persistence

  @impl true
  def mount(_params, _session, socket) do
    {:ok, user} = Persistence.get_user()

    {:ok, assign(socket, user: user)}
  end

  @impl true
  def handle_event(event, params, socket) do
    {:noreply, socket}
  end

  @impl true

  def handle_info(message, socket) do
    Logger.error("Unknow message received: #{inspect(message)}")
    {:noreply, socket |> put_flash(:error, "Something unexpected happened, please report it!")}
  end
end
