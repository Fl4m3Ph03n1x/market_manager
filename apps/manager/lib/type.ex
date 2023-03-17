defmodule Manager.Type do
  @moduledoc """
  Holds the types for the Manager library.
  """

  alias Shared.Data.{Credentials, User}

  ##########
  # Types  #
  ##########

  @type syndicate :: String.t()
  @type strategy :: atom
  @type error_reason :: atom
  @type order_id :: String.t()
  @type item_id :: String.t()

  @type handle :: (result :: any -> :ok)

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

  @type login_response :: {:ok, User.t()} | {:error, error_reason, Credentials.t()}
end
