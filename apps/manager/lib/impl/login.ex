defmodule Manager.Impl.Login do
  @moduledoc """

  """

  alias AuctionHouse
  alias Manager.Type

  alias Shared.Data.{
    Authorization,
    Credentials,
    User
  }

  alias Store

  @default_deps %{
    store: Store,
    auction_house: AuctionHouse
  }

  @typep keep_logged_in :: boolean()

  @spec request_user_login(
          Credentials.t(),
          metadata :: map(),
          Type.dependencies()
        ) ::
          Type.login_response()
  def request_user_login(
        credentials,
        metadata,
        %{auction_house: auction_house} = deps \\ @default_deps
      ) do
    auction_house.login(credentials, metadata)
  end

  def acknowledge_login(
        {:ok, _login_data},
        %{keep_logged_in: false},
        %{store: store} \\ @default_deps
      ),
      do: store.delete_login_data()

  def acknowledge_login(
        {:ok, %{auth: auth, user: user}},
        %{keep_logged_in: true},
        %{store: store} \\ @default_deps
      ),
      do: store.save_login_data(auth, user)

  @spec recover_login(Type.dependencies()) :: Type.recover_login_response()
  def recover_login(%{store: store, auction_house: auction_house} \\ @default_deps) do
    with {:ok, {auth, user}} <- store.get_login_data(),
         :ok <- auction_house.recover_login(auth, user) do
      {:ok, user}
    end
  end
end
