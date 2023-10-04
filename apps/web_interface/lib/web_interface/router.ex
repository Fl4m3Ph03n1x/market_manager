defmodule WebInterface.Router do
  use WebInterface, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {WebInterface.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", WebInterface do
    pipe_through :browser

    get "/", PageController, :home

    live "/profile", ProfileLive
    live "/login", LoginLive
    live "/logout", LogoutLive
    live "/activate", ActivateLive
    live "/deactivate", DeactivateLive
  end

  # Other scopes may use custom stacks.
  # scope "/api", WebInterface do
  #   pipe_through :api
  # end
end
