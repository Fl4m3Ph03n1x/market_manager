defmodule Manager do
  @moduledoc """
  MarketManager is an application that allows you to make batch requests to
  warframe.market. This is the entrypoint of everything. If you have a module
  and you need to talk to MarketManager, this is who you call, the public API.
  """

  alias Manager.{Interpreter, PriceAnalyst, Server}
  alias Store

  ##########
  # Types  #
  ##########

  @type syndicate :: String.t
  @type strategy :: atom
  @type error_reason :: atom
  @type order_id :: String.t
  @type item_id :: String.t

  #############
  # Responses #
  #############

  @type activate_response ::
    {:ok, :success}
    | {:partial_success, [{:error, error_reason, item_id}, ...]}
    | {:error, :unable_to_place_requests, [{:error, error_reason, item_id}]}

  @type deactivate_response ::
    {:ok, :success}
    | {:partial_success, [{:error, error_reason, order_id}, ...]}
    | {:error, :unable_to_delete_orders, [{:error, error_reason, order_id}]}

  @type setup_response ::
    {:ok, Store.login_info}
    | {:error, :unable_to_save_setup, [{:error, :missing_token | :missing_cookie | :file.posix, Store.login_info}]}

  ##########
  # Public #
  ##########

  @doc """
  Activates a syndicate in warframe.market. Activating a syndicate means you
  put on sell all the mods the syndicate has with that are in the *products.json*
  file. The price of each mod will be calculated via a PriceAnalyst depending on
  which strategy you choose.

  Example:
  ```
  > MarketManager.activate("simaris", :lowest_minus_one)
  {:ok, :success}
  ```
  """
  @spec activate(syndicate, strategy) :: activate_response
  defdelegate activate(syndicate, strategy), to: Interpreter

  @doc """
  Deactivates a syndicate in warframe.market. Deactivating a syndicate means you
  delete all orders you have placed before that belong to the given syndicate.

  Example:
  ```
  > MarketManager.deactivate("simaris")
  {:ok, :success}
  ```
  """
  @spec deactivate(syndicate) :: deactivate_response
  defdelegate deactivate(syndicate), to: Interpreter

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
  @spec valid_strategy?(String.t) :: boolean
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
  @spec valid_action?(String.t) :: boolean
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
  @spec valid_syndicate?(syndicate) :: Store.syndicate_exists_response
  defdelegate valid_syndicate?(syndicate), to: Store, as: :syndicate_exists?

  @doc """
  Saves the setup login information used in all requests.
  Required parameters are:

    - token: the xrfc-token used to send requests
    - cookie: the cookie used to id the user

  Performs validation on the given information.

  Example:
  ```
  > MarketManager.setup(%{"token" => "abc", "cookie" => "123"})
  {:ok, %{"token" => "abc", "cookie" => "123"}}

  > MarketManager.setup(%{"token" => "abc"})
  {:error, :unable_to_save_setup, {:missing_mandatory_keys, ["cookie"], %{"token" => "abc"}}}

  > MarketManager.setup(%{"token" => "abc", "cookie" => "123"})
  {:error, :unable_to_save_setup, {:enoent, %{"token" => "abc", "cookie" => "123"}}}
  ```
  """
  @spec setup(Store.login_info) :: setup_response
  defdelegate setup(data), to: Interpreter

  @doc false
  @spec child_spec(any) :: %{
    :id => any,
    :start => {atom, atom, [any]},
    optional(:modules) => :dynamic | [atom],
    optional(:restart) => :permanent | :temporary | :transient,
    optional(:shutdown) => :brutal_kill | :infinity | non_neg_integer,
    optional(:type) => :supervisor | :worker
  }
  defdelegate child_spec(args), to: Server
end
