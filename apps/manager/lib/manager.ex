defmodule Manager do
  @moduledoc """
  MarketManager is an application that allows you to make batch requests to
  warframe.market. This is the entrypoint of everything. If you have a module
  and you need to talk to MarketManager, this is who you call, the public API.
  """

  alias Manager.Type
  alias Manager.Impl.Interpreter
  alias Manager.Runtime.{Server, Worker}
  alias Supervisor

  ##########
  # Public #
  ##########

  @doc """
  Activates a syndicate in warframe.market. Activating a syndicate means you
  put on sell all the mods the syndicate has. The price of each mod will be calculated via a
  `PriceAnalyst` depending on which strategy you choose.

  This is an asynchronous operation, which will return `:ok` immediatly.
  The caller must have implemented a `handle_info` in its Server to handle messages with the
  following format:

  - `{:activate, syndicate :: String.t(), {index :: pos_integer(), total :: pos_integer(), result :: any}}`:
    Each time a placement for an item is done. This message contains the current index, the total
    and the result of the operation. It also has the id of the syndicate this order placement
    belongs to.
    The `result` of an operation, will be a tagged tuple. Some common formats are:

     - `{:ok, order_id :: String.t()}`, when the placement was successfull
     - `{:error, reason :: any(), item_id :: String.t()}`, when the placement failed

  - `{:activate, syndicate :: String.t(), :done}`: Once all orders have been placed (successfully
    or not). It is the end of the `:activate` operation. It also has the id of the syndicate for
    which this operation was completed for.
  - `{:activate, syndicate :: String.t(), error :: any}`: If a critical error occurred while trying
    to perform the `:activate` operation and this cannot continue/succeed. It also signals the end
    of the operation. Contains the id of the syndicate for which the operation failed.

  Example:
  ```
  > MarketManager.activate("cephalon_simaris", :lowest_minus_one)
  :ok
  ```
  """
  @spec activate(Type.syndicate(), Type.strategy()) :: :ok
  defdelegate activate(syndicate, strategy), to: Worker

  @doc """
  Deactivates a syndicate in warframe.market. Deactivating a syndicate means you
  delete all orders you have placed before that belong to the given syndicate.

  This is an asynchronous operation, which will return `:ok` immediatly.
  The caller must have implemented a `handle_info` in its Server to handle messages with the
  following format:

  - `{:deactivate, syndicate :: String.t(), {index :: pos_integer(), total :: pos_integer(), result :: any}}`:
    Each time a placement for an item is done. This message contains the current index, the total
    and the result of the operation. It also has the id of the syndicate this order placement
    belongs to.
    The `result` of an operation, will be a tagged tuple. Some common formats are:

     - `{:ok, order_id :: String.t()}`, when the deletion was successfull
     - `{:error, reason :: any(), order_id :: String.t()}`, when the deletion failed

  - `{:deactivate, syndicate :: String.t(), :done}`: Once all orders have been deleted (successfully
    or not). It is the end of the `:deactivate` operation. It also has the id of the syndicate for
    which this operation was completed for.
  - `{:deactivate, syndicate :: String.t(), error :: any}`: If a critical error occurred while trying
    to perform the `:deactivate` operation and this cannot continue/succeed. It also signals the end
    of the operation. Contains the id of the syndicate for which the operation failed.

  Example:
  ```
  > MarketManager.deactivate("cephalon_simaris")
  :ok
  ```
  """
  @spec deactivate(Type.syndicate()) :: :ok
  defdelegate deactivate(syndicate), to: Worker

  @doc """
  Saves the login information used in all requests.
  Required parameters are:

    - token: the xrfc-token used to send requests
    - cookie: the cookie used to id the user

  Performs validation on the given information.

  Example:
  ```
  > MarketManager.authenticate(%{"token" => "abc", "cookie" => "123"})
  {:ok, %{"token" => "abc", "cookie" => "123"}}

  > MarketManager.authenticate(%{"token" => "abc"})
  {:error, :unable_to_save_authentication, {:missing_mandatory_keys, ["cookie"], %{"token" => "abc"}}}

  > MarketManager.authenticate(%{"token" => "abc", "cookie" => "123"})
  {:error, :unable_to_save_authentication, {:enoent, %{"token" => "abc", "cookie" => "123"}}}
  ```
  """
  @spec authenticate(Type.credentials()) :: Type.authenticate_response()
  defdelegate authenticate(credentials), to: Interpreter

  @doc false
  @spec child_spec(any) :: Supervisor.child_spec()
  defdelegate child_spec(args), to: Server
end
