defmodule WebInterface.ActivateLive do
  use WebInterface, :live_view

  require Logger

  alias Manager
  alias Shared.Data.{Credentials, User}

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_event(event, params, socket) do
    IO.inspect(event, label: "EVENT")
    IO.inspect(params, label: "PARAMS")
    IO.inspect(socket, label: "SOCKET")

    {:noreply, socket}
  end

  @impl true

  def handle_info(message, socket) do
    Logger.error("Unknow message received: #{inspect(message)}")
    {:noreply, socket |> put_flash(:error, "Something unexpected happened, please report it!")}
  end
end
