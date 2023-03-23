defmodule Manager.Type do
  @moduledoc """
  Holds the types for the Manager library.
  """

  alias Shared.Data.{Credentials, PlacedOrder, User}

  ##########
  # Types  #
  ##########

  @type syndicate :: String.t()
  @type strategy :: atom
  @type error_reason :: atom
  @type item_id :: String.t()
  @type handle :: (result :: any -> :ok)
  @type dependencies :: keyword(module)

  #############
  # Responses #
  #############

  @type activate_response ::
          {:ok, :success}
          | {:partial_success, [{:error, error_reason, item_id}, ...]}
          | {:error, :unable_to_place_requests, [{:error, error_reason, item_id}]}

  @type deactivate_response ::
          {:ok, :success}
          | {:partial_success, [{:error, error_reason, PlacedOrder.t()}, ...]}
          | {:error, :unable_to_delete_orders, [{:error, error_reason, PlacedOrder.t()}]}

  @type login_response :: {:ok, User.t()} | {:error, error_reason, Credentials.t()}
end
