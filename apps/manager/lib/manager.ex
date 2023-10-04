defmodule Manager do
  @moduledoc """
  MarketManager is an application that allows you to make batch requests to
  warframe.market. This is the entrypoint of everything. If you have a module
  and you need to talk to MarketManager, this is who you call, the public API.
  """

  alias Manager.Type
  alias Manager.Runtime.{Server, Worker}
  alias Shared.Data.{Credentials, Strategy, Syndicate}

  ##########
  # Public #
  ##########

  @doc """
  Asynchronous operation.

  Activates a syndicate in warframe.market. Activating a syndicate means you
  put on sell all the mods the syndicate has. The price of each mod will be calculated via a
  `PriceAnalyst` depending on which strategy you choose.

  This is an asynchronous operation, which will return `:ok` immediately.
  The caller must have implemented a `handle_info` in its Server to handle messages with the
  following format:

  - `{:activate, syndicate :: String.t(), {index :: pos_integer(), total :: pos_integer(), result :: any}}`:
    Each time a placement for an item is done. This message contains the current index, the total
    and the result of the operation. It also has the id of the syndicate this order placement
    belongs to.
    The `result` of an operation, will be a tagged tuple. Some common formats are:

     - `{:ok, order_id :: String.t()}`, when the placement was successful
     - `{:error, reason :: any(), item_id :: String.t()}`, when the placement failed

  - `{:activate, syndicate :: String.t(), :done}`: Once all orders have been placed (successfully
    or not). It is the end of the `:activate` operation. It also has the id of the syndicate for
    which this operation was completed for.
  - `{:activate, syndicate :: String.t(), error :: any}`: If a critical error occurred while trying
    to perform the `:activate` operation and this cannot continue/succeed. It also signals the end
    of the operation. Contains the id of the syndicate for which the operation failed.

  Example:
  ```
  > Manager.activate("cephalon_simaris", :lowest_minus_one)
  :ok
  ```
  """
  @spec activate(Syndicate.t(), Strategy.t()) :: :ok
  defdelegate activate(syndicate, strategy), to: Worker

  @doc """
  Asynchronous operation.

  Deactivates a syndicate in warframe.market. Deactivating a syndicate means you
  delete all orders you have placed before that belong to the given syndicate.

  This is an asynchronous operation, which will return `:ok` immediately.
  The caller must have implemented a `handle_info` in its Server to handle messages with the
  following format:

  - `{:deactivate, syndicate :: String.t(), {index :: pos_integer(), total :: pos_integer(), result :: any}}`:
    Each time a placement for an item is done. This message contains the current index, the total
    and the result of the operation. It also has the id of the syndicate this order placement
    belongs to.
    The `result` of an operation, will be a tagged tuple. Some common formats are:

     - `{:ok, order_id :: String.t()}`, when the deletion was successful
     - `{:error, reason :: any(), order_id :: String.t()}`, when the deletion failed

  - `{:deactivate, syndicate :: String.t(), :done}`: Once all orders have been deleted (successfully
    or not). It is the end of the `:deactivate` operation. It also has the id of the syndicate for
    which this operation was completed for.
  - `{:deactivate, syndicate :: String.t(), error :: any}`: If a critical error occurred while trying
    to perform the `:deactivate` operation and this cannot continue/succeed. It also signals the end
    of the operation. Contains the id of the syndicate for which the operation failed.

  Example:
  ```
  > Manager.deactivate("cephalon_simaris")
  :ok
  ```
  """
  @spec deactivate(Syndicate.t()) :: :ok
  defdelegate deactivate(syndicate), to: Worker

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

  - `{:login, user_info :: Shared.Data.User.t(), :done}`: If the operation was successful.

  - `{:login, credentials :: Shared.Data.Credentials.t(), error :: any}`: If the login operation failed.
    This can happen due to a network error, wrong password or any other cause.

  Example:
  ```
  > alias Shared.Data.Credentials

  > credentials = Credentials.new("username", "password")

  > Manager.login(credentials, false)
  :ok
  ```
  """
  @spec login(Credentials.t(), keep_logged_in :: boolean) ::
          Type.login_response()
  defdelegate login(credentials, keep_logged_in), to: Worker

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
  login session in the AuctionHouse. If a user is logged in the AuctionHouse, it will continue logged in there, but next
  time this application is launched, the user will have to login into the AuctionHouse from this application to be able
  to use it.

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
  {:ok, [%Syndicate{name: "Red Veil", id: :red_veil}]}

  > Manager.syndicates()
  {:error, :enoent}
  ```
  """
  @spec syndicates :: Type.syndicates_response()
  defdelegate syndicates, to: Worker

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
  defdelegate child_spec(args), to: Server

end
