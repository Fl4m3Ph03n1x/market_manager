defmodule WebInterface.LoginLive do
  use WebInterface, :live_view

  require Logger

  alias Manager
  alias Shared.Data.{Credentials, User}
  alias WebInterface.Persistence.User, as: UserStore

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, logging_in: false)}
  end

  ###################
  # Frontend Events #
  ###################

  @impl true
  def handle_event("login", %{"email" => email, "password" => password} = params, socket) do
    IO.inspect(params, label: "PARAMS")

    :ok =
      email
      |> Credentials.new(password)
      |> Manager.login(Map.has_key?(params, "remember-me"))

    # show spinning wheel animation
    {:noreply, assign(socket, logging_in: true)}
  end

  ##################
  # Backend Events #
  ##################

  @impl true
  def handle_info({:login, {:ok, %User{} = user}}, socket) do
    Logger.info("Authentication succeeded for user #{inspect(user)}")

    :ok = UserStore.set_user(user)

    socket =
      socket
      |> assign(logging_in: false)
      |> redirect(to: ~p"/activate")

    {:noreply, socket}
  end

  def handle_info({:login, {:error, :econnrefused, _data}}, socket) do
    socket =
      socket
      |> assign(logging_in: false)
      |> put_flash(:error, "Unable to connect to warframe.market. Please verify your internet connection.")

    {:noreply, socket}
  end

  def handle_info({:login, {:error, :wrong_password}}, socket) do
    socket =
      socket
      |> assign(logging_in: false)
      |> put_flash(:error, "Incorrect Password!")

    {:noreply, socket}
  end

  def handle_info({:login, {:error, :wrong_email}}, socket) do
    socket =
      socket
      |> assign(logging_in: false)
      |> put_flash(:error, "Your email is incorrect or does not exist!")

    {:noreply, socket}
  end

  def handle_info({:login, {:error, :invalid_email, _data}}, socket) do
    socket =
      socket
      |> assign(logging_in: false)
      |> put_flash(:error, "Please provide a valid email!")

    {:noreply, socket}
  end

  def handle_info({:login, {:error, :timeout, _data}}, socket) do
    socket =
      socket
      |> assign(logging_in: false)
      |> put_flash(:error, "The request timed out, try again later!")

    {:noreply, socket}
  end

  def handle_info({:login, {:error, :unknown_error, _data}}, socket) do
    socket =
      socket
      |> assign(logging_in: false)
      |> put_flash(:error, "An unknown error occurred, please report it!")

    {:noreply, socket}
  end

  def handle_info(message, socket) do
    Logger.error("Unknown message received: #{inspect(message)}")
    {:noreply, socket |> put_flash(:error, "Something unexpected happened, please report it!")}
  end
end
