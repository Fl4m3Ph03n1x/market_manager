defmodule WebInterface.UserLoginLive do
  use WebInterface, :live_view

  require Logger

  alias Manager
  alias Shared.Data.{Credentials, User}
  alias WebInterface.Persistence.User, as: UserStore

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_event("login", %{"email" => email, "password" => password} = params, socket) do
    :ok =
      email
      |> Credentials.new(password)
      |> Manager.login(Map.has_key?(params, "remember-me"))

      # show spinning wheel animation
      {:noreply, socket}
  end

  @impl true
  def handle_info({:login, %User{} = user, :done}, socket) do
    Logger.info("Authentication succeeded for user #{inspect(user)}")

    :ok = UserStore.set_user(user)

    {:noreply,  socket |> redirect(to: ~p"/activate")}
  end

  def handle_info({:login, _credentials, {:error, :econnrefused, _data}}, socket) do
    {:noreply, socket |> put_flash(:error, "Unable to connect to warframe.market. Please verify your internet connection.")}
  end

  def handle_info({:login, _credentials, {:error, :wrong_password, _data}}, socket) do
    {:noreply, socket |> put_flash(:error, "Incorrect Password!")}
  end

  def handle_info({:login, _credentials, {:error, :wrong_email, _data}}, socket) do
    {:noreply, socket |> put_flash(:error, "Your email is incorrect or does not exist!")}
  end

  def handle_info({:login, _credentials, {:error, :invalid_email, _data}}, socket) do
    {:noreply, socket |> put_flash(:error, "Please provide a valid email!")}
  end

  def handle_info({:login, _credentials, {:error, :timeout, _data}}, socket) do
    {:noreply, socket |> put_flash(:error, "The request timedout, try again later!")}
  end

  def handle_info({:login, _credentials, {:error, :unknown_error, _data}}, socket) do
    {:noreply, socket |> put_flash(:error, "An unknown error ocurred, please report it!")}
  end

  def handle_info(message, socket) do
    Logger.error("Unknow message received: #{inspect(message)}")
    {:noreply, socket |> put_flash(:error, "Something unexpected happened, please report it!")}
  end

end
