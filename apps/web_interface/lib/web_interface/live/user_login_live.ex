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
  def handle_event("login",  %{"email" => email, "password" => password} = params, socket) do
    remember? = Map.has_key?(params, "remember-me")
    credentials = Credentials.new(email, password)

    case Manager.login(credentials, remember?) do
      {:ok, _user} -> {:noreply, socket |> redirect(to: ~p"/")}
      {:error, reason, data} ->   {:noreply, socket |> put_flash(:error, "Login failed with reason: #{reason}")}
      Logger.error("Login failed. Reason: #{reason}\tData: #{data}")
    end
  end
end
