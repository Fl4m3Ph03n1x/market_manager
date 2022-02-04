defmodule Manager.Type do
  @moduledoc """
  Holds the types for the Manager library.
  """

  ##########
  # Types  #
  ##########

  @type syndicate :: String.t
  @type strategy :: atom
  @type error_reason :: atom
  @type order_id :: String.t
  @type item_id :: String.t
  @type credentials :: %{
    (cookie :: String.t) => String.t,
    (token :: String.t) => String.t
  }

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

  @type authenticate_response ::
    {:ok, credentials}
    | {:error, :unable_to_save_authenticate, [{:error, :missing_token | :missing_cookie | :file.posix, credentials}]}

end
