defmodule MarketManager do
  @moduledoc """
  MarketManager is an application that allows you to make batch requests to
  warframe.market. This is the entrypoint of everything. If you have a module
  and you need to talk to MarketManager, this is who you call, the public API.
  """

  alias MarketManager.Interpreter

  ##########
  # Types  #
  ##########

  @type syndicate :: String.t
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

  #############
  # Callbacks #
  #############

  @doc """
  Activates a syndicate in warframe.market. Activating a syndicate means you
  put on sell all the mods the syndicate has with the prices you specify on
  "products.json".

  Example:
  ```
  {:ok, :success} = MarketManager.activate("simaris")
  ```
  """
  @spec activate(syndicate) :: activate_response
  def activate(syndicate), do: Interpreter.activate(syndicate)

  @doc """
  Deactivates a syndicate in warframe.market. Deactivating a syndicate means you
  delete all orders you have placed before that belong to the given syndicate.

  Example:
  ```
  {:ok, :success} = MarketManager.deactivate("simaris")
  ```
  """
  @spec deactivate(syndicate) :: deactivate_response
  def deactivate(syndicate), do: Interpreter.deactivate(syndicate)
end
