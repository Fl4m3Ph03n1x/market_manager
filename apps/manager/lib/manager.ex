defmodule Manager do
  @moduledoc """
  MarketManager is an application that allows you to make batch requests to
  warframe.market. This is the entrypoint of everything. If you have a module
  and you need to talk to MarketManager, this is who you call, the public API.
  """

  alias Manager.Type
  alias Manager.Runtime.{ManagerSupervisor, SagaSupervisor, Worker}
  alias Shared.Data.{Credentials, Strategy, Syndicate}

  ##########
  # Public #
  ##########

  @doc """
  Asynchronous operation.

  Activates a syndicate in warframe.market. Activating a syndicate means you
  put on sell all the mods/arcanes the syndicate has. The price of each mod will be calculated via a
  `PriceAnalyst` depending on which strategy you choose.

  This is an asynchronous operation, which will return `:ok` immediately.
  The caller must have implemented a `handle_info` in its Server to handle messages with the
  following format:

  - `{:activate, {:ok, :get_user_orders}}`: Informs that a request was made to get current user orders.
  - `{:activate, {:ok, :calculating_item_prices}}`: Informs that the Manager is now calculating prices for all the items of the selected syndicates.
  - `{:activate, {:ok, {:price_calculated, item_name, price, current_progress, total_progress}}}`: Informs that "price" was successfully calculated for "item_name". It also give the "current_progress" and "total_progress" for the caller to know how long the operation will take.
  - `{:activate, {:ok, :placing_orders}}`: Informs that the final stage, of placing orders, has now begun.
  - `{:activate, {:ok, {:order_placed, item_name, current_progress, total_progress}}}`: Informs that an order with "price" was successfully posted in Warframe Market for "item_name". It also gives the "current_progress" and "total_progress" for the caller to know how long the operation will take.
  - `{:activate, {:ok, :done}}`: Informs the process is now complete.

  Any other received messages will be of the format `{:error, any()}` and mean that something has failed during the activation process.


  Example:
  ```
  > Manager.activate(%{cephalon_simaris: :lowest_minus_one})
  :ok
  ```
  """
  @spec activate(%{Syndicate.id() => Strategy.id()}) :: Type.activate_response()
  defdelegate activate(syndicates_with_strategy), to: SagaSupervisor

  @doc """
  Asynchronous operation.

  Deactivates a syndicate in warframe.market. Deactivating a syndicate means you delete all orders you have placed that belong to the given syndicate.

  This is an asynchronous operation, which will return `:ok` immediately.
  The caller must have implemented a `handle_info` in its Server to handle messages with the following format:

  - `{:deactivate, {:ok, :get_user_orders}}`: Informs that a request was made to get current user orders.
  - `{:deactivate, {:ok, :deleting_orders}}`: Informs that the Manager started deleting orders.
  - `{:deactivate, {:ok, {:order_deleted, item_name, current_progress, total_progress}}}`: Informs that the order for "item_name" was successfully deleted in Warframe Market. It also gives the "current_progress" and "total_progress" for the caller to know how long the operation will take.
  - `{:deactivate, {:ok, :done}}`: Informs the process is not complete.

  Optionally, if the deactivation was partial, meaning there are still some syndicates active, instead of receiving `{:deactivate, {:ok, :done}}`, the caller will instead receive:
  - `{:deactivate, {:ok, :reactivating_remaining_syndicates}}`

  Which informs that the activation process for the remaining syndicates will now begin, in order to update the selection of current items on sale and their prices. Consequently, all messages from the Activation process also need to be handled by the caller.

  Example:
  ```
  > Manager.deactivate([:cephalon_simaris])
  :ok
  ```
  """
  @spec deactivate([Syndicate.id()]) :: Type.deactivate_response()
  defdelegate deactivate(syndicate_ids), to: SagaSupervisor

  @doc """
  Asynchronous operation.

  Saves the login information used in all requests. Can optionally keep user
  logged in for future sessions. Will first attempt to authenticate the user,
  and then, if successful and if `keep_logged_in` is `true`, will try to save
  the authentication parameters. Should it fail to save the authentication
  parameters, the login request is still done.

  This is an asynchronous operation, which will return `:ok` immediately.
  The caller must have implemented a `handle_info` in its Server to handle messages with the
  following format:

  - `{:login, {:ok, user_info :: Shared.Data.User.t()}}`: If the operation was successful.

  - `{:login, {:error, error :: any()}}`: If the login operation failed.
    This can happen due to a network error, wrong password or any other cause.

  Example:
  ```
  > alias Shared.Data.Credentials

  > credentials = Credentials.new("username", "password")

  > Manager.login(credentials, false)
  :ok
  ```
  """
  @spec login(Credentials.t(), keep_logged_in :: boolean) :: Type.login_response()
  defdelegate login(credentials, keep_logged_in), to: SagaSupervisor

  @doc """
  Synchronous operation.

  Login into the application using a previous session.
  If this operation is attempted and the user has not logged in yet, `nil` is returned instead of a User.

  Example:
  ```
  > alias Shared.Data.User

  > Manager.recover_login()
  {:ok, %User{ingame_name: "user_1", patreon?: false}}

  > Manager.recover_login()
  {:ok, nil}

  > Manager.recover_login()
  {:error, :enoent}
  ```
  """
  @spec recover_login :: Type.recover_login_response()
  defdelegate recover_login, to: Worker

  @doc """
  Synchronous operation.

  Deletes the current active session. This only logs out the MarketManager application and does not affect the
  login session in the AuctionHouse. If a user is logged in the AuctionHouse, it will continue  to be logged in there,
  but next time this application is launched, the user will have to login into the AuctionHouse from this application
  to be able to use it.

  This operation deletes the sessions data from memory and from disk. Even if the second fails, the first will still
  be attempted.

  Example:
  ```
  > Manager.logout()
  :ok

  > Manager.logout()
  {:error, :reason}
  ```
  """
  @spec logout :: Type.logout_response()
  defdelegate logout, to: Worker

  @doc """
  Synchronous operation.

  Returns the list of known syndicates, or an error if it fails.

  Example:
  ```
  > alias Shared.Data.Syndicate

  > MarketManager.syndicates()
  {:ok, [%Syndicate{name: "Red Veil", id: :red_veil, catalog: []}]}

  > Manager.syndicates()
  {:error, :enoent}
  ```
  """
  @spec syndicates :: Type.syndicates_response()
  defdelegate syndicates, to: Worker

  @doc """
  Synchronous operation.

  Returns a list containing all currently active syndicates with their strategies.

  Example:
  ```
  > alias Shared.Data.Syndicate

  > MarketManager.active_syndicates()
  {:ok, %{red_veil: :top_five_average, new_loka: :top_five_average}}

  > Manager.active_syndicates()
  {:error, :enoent}
  ```
  """
  @spec active_syndicates :: Type.active_syndicates_response()
  defdelegate active_syndicates, to: Worker

  @doc """
  Synchronous operation.

  Returns the list of available strategies, or an error if it fails.

  Example:
  ```
  > alias Shared.Data.Strategy

  > Manager.strategies()
  {:ok, [
    %Strategy{
      name: "Top 3 Average",
      id: :top_three_average,
      description: "Gets the 3 lowest prices for the given item and calculates the average."
    },
    %Strategy{
      name: "Top 5 Average",
      id: :top_five_average,
      description: "Gets the 5 lowest prices for the given item and calculates the average."
    }
  ]}

  > Manager.strategies()
  {:error, :reason}
  ```
  """
  @spec strategies :: {:ok, [Strategy.t()]} | {:error, any}
  defdelegate strategies, to: Worker

  @doc false
  @spec child_spec(any) :: Supervisor.child_spec()
  defdelegate child_spec(args), to: ManagerSupervisor
end
