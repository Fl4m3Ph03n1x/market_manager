defmodule MarketManager do
  @moduledoc """
  Documentation for MarketManager.
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

  @spec activate(syndicate) :: activate_response
  def activate(syndicate), do: Interpreter.activate(syndicate)

  @spec deactivate(syndicate) :: deactivate_response
  def deactivate(syndicate), do: Interpreter.deactivate(syndicate)
end
