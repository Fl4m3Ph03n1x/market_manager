defmodule WebInterface.PageController do
  use WebInterface, :controller

  alias WebInterface.Persistence.User, as: UserStore

  def home(conn, _params) do
    if UserStore.has_user?() do
      redirect(conn, to: ~p"/activate")
    else
      redirect(conn, to: ~p"/login")
    end
  end
end
