defmodule WebInterface.UserLoginLive do
  use WebInterface, :live_view

  require Logger

  alias Manager
  alias Shared.Data.{Credentials, User}

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

    {:noreply, socket}
    # case Manager.login(credentials, remember?) do
    #   {:ok, _user} -> {:noreply, socket |> redirect(to: ~p"/")}
    #   {:error, reason, data} ->   {:noreply, socket |> put_flash(:error, "Login failed with reason: #{reason}")}
    #   Logger.error("Login failed. Reason: #{reason}\tData: #{data}")
    # end
  end

  @impl true
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

  def handle_info({:login, _credentials, {:error, :unknown_error, _data}}, socket) do
    {:noreply, socket |> put_flash(:error, "An unknown error ocurred, please report it !")}
  end

  def handle_info(message, socket) do
    IO.inspect(message, label: "MESSAGE")
    IO.inspect(socket, label: "SOCKET")

    {:noreply, socket}
  end
end
