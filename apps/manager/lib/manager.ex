defmodule Manager do
  @moduledoc """
  MarketManager is an application that allows you to make batch requests to
  warframe.market. This is the entrypoint of everything. If you have a module
  and you need to talk to MarketManager, this is who you call, the public API.
  """

  alias Manager.Type
  alias Manager.Impl.{Interpreter, PriceAnalyst}
  alias Manager.Runtime.{Server, Worker}
  alias Store.Type, as: StoreTypes
  alias Supervisor

  ##########
  # Public #
  ##########

  @doc """
  Activates a syndicate in warframe.market. Activating a syndicate means you
  put on sell all the mods the syndicate has with that are in the *products.json*
  file. The price of each mod will be calculated via a PriceAnalyst depending on
  which strategy you choose.

  This is an asynchronous operation, which will return immediatly.
  The caller must have implemented a `handle_info` in its Server to have messages with the
  following format:

  - `{:activate, {index :: pos_integer(), total :: pos_integer(), result :: any}}`: Each time an
    a placement for an item is done. This message contains the current index, the total and the
    result of the operation.
  - `{:activate, :done}`: Once all orders have been placed (successfully or not). It is the end
    of the `:activate` operation.
  - `{:activate, error :: any}`: If a critical error occurred while trying to perform the
    `:activate` operation and this cannot continue/succeed. It also signals the end of the
    operation.

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

  Example:
  ```
  > MarketManager.deactivate("cephalon_simaris")
  {:ok, :success}
  ```
  """
  @spec deactivate(Type.syndicate()) :: :ok
  defdelegate deactivate(syndicate), to: Worker

  @doc """
  Returns true if the given strategy is valid, false otherwise.

  Example:
  ```
  > MarketManager.valid_strategy?("bananas")
  false
  > MarketManager.valid_strategy?("equal_to_lowest")
  true
  ```
  """
  @spec valid_strategy?(String.t()) :: boolean
  defdelegate valid_strategy?(strategy), to: PriceAnalyst

  @doc """
  Returns true if the given action is valid, false otherwise.

  Example:
  ```
  > MarketManager.valid_action?("bananas")
  false
  > MarketManager.valid_action?("activate")
  true
  ```
  """
  @spec valid_action?(String.t()) :: boolean
  defdelegate valid_action?(action), to: Interpreter

  @doc """
  Returns true if the given syndicate is valid, false otherwise.
  A syndicate is considered to be valid if it has an entry in the products.json
  file, even if that entry is empty. Returns error if an error occurs, like for
  example the products.json file not existing.

  Example:
  ```
  > MarketManager.valid_syndicate?("bananas")
  {:ok, false}

  > MarketManager.valid_syndicate?("red_veil")
  {:ok, true}

  > MarketManager.valid_syndicate?("red_veil") # products.json not found
  {:error, :enoent}
  ```
  """
  @spec valid_syndicate?(Type.syndicate()) :: StoreTypes.syndicate_exists_response()
  defdelegate valid_syndicate?(syndicate), to: Store, as: :syndicate_exists?

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
