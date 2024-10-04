defmodule Manager.UseCase.Login do
  use GenServer, restart: :transient

  alias AuctionHouse

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

  ##########
  # Client #
  ##########

  def start_link(
        %{from: from, args: %{credentials: _credentials, keep_logged_in: _keep_logged_in}} = state
      ) do
    updated_state = %{
      deps: Map.merge(@default_deps, Map.get(state, :deps, %{})),
      args: state.args,
      from: from
    }

    GenServer.start_link(__MODULE__, updated_state)
  end

  #############
  # Callbacks #
  #############

  @impl GenServer
  def init(state), do: {:ok, state, {:continue, nil}}

  @impl GenServer
  def handle_continue(
        nil,
        %{
          deps: %{store: store, auction_house: auction_house},
          args: %{credentials: credentials, keep_logged_in: keep_logged_in},
          from: from
        } = state
      ) do
    with {:ok, {authorization, user}} <- store.get_login_data(),
         :ok <- auction_house.update_login(authorization, user) do
      if keep_logged_in do
        store.save_login_data(authorization, user)
      else
        store.delete_login_data()
      end
      # we fetched the user info from storage and updated the auction server correctly
      send(from, {:login, {:ok, user}})
    else
      # we have no login saved
      {:ok, nil} ->
        auction_house.login(credentials)

      # the storage file probably does not exist or some storage error happened
      {:error, _reason} ->
        auction_house.login(credentials)
    end

    {:noreply, state}
  end

  @impl GenServer
  def handle_info(
        {:login, {:ok, {authorization, user}}},
        %{
          deps: %{store: store},
          args: %{keep_logged_in: keep_logged_in},
          from: from
        } = state
      ) do
    if keep_logged_in do
      store.save_login_data(authorization, user)
    else
      store.delete_login_data()
    end

    send(from, {:login, {:ok, user}})

    {:stop, :normal, state}
  end

  def handle_info({:login, {:error, reason}} = err, %{from: from} = state) do
    send(from, err)
    {:stop, :normal, state}
  end
end
