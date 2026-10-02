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

  def handle_info({:login, {:error, :request_failed}}, socket) do
    socket =
      socket
      |> assign(logging_in: false)
      |> put_flash(:error, "Unable to connect to warframe.market. Please verify your internet connection.")

    {:noreply, socket}
  end

  def handle_info({:login, {:error, :unauthorized}}, socket) do
    socket =
      socket
      |> assign(logging_in: false)
      |> put_flash(:error, "warframe.market rejected the login. Please try again.")

    {:noreply, socket}
  end

  def handle_info({:login, {:error, :forbidden}}, socket) do
    socket =
      socket
      |> assign(logging_in: false)
      |> put_flash(:error, "warframe.market denied access to this account. Please check your account on the website.")

    {:noreply, socket}
  end

  def handle_info({:login, {:error, reason}}, socket) when reason in [:bad_request, :not_found] do
    socket =
      socket
      |> assign(logging_in: false)
      |> put_flash(:error, "warframe.market sent an unexpected response. Please try again later.")

    {:noreply, socket}
  end

  def handle_info({:login, {:error, {reason, _headers}}}, socket)
      when reason in [:missing_token, :invalid_token_format] do
    socket =
      socket
      |> assign(logging_in: false)
      |> put_flash(:error, "warframe.market sent an unexpected response. Please try again later.")

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

  def handle_info({:login, {:error, :invalid_email}}, socket) do
    socket =
      socket
      |> assign(logging_in: false)
      |> put_flash(:error, "Please provide a valid email!")

    {:noreply, socket}
  end

  def handle_info({:login, {:error, :unknown_error}}, socket) do
    socket =
      socket
      |> assign(logging_in: false)
      |> put_flash(:error, "An unknown error occurred, please report it!")

    {:noreply, socket}
  end

  def handle_info(message, socket) do
    socket =
      socket
      |> assign(logging_in: false)
      |> put_flash(:error, "Unknown message received, please check the logs and report it!")

    Logger.error("Unknown message received: #{inspect(message)}")
    {:noreply, socket}
  end
end
