defmodule AuctionHouse.Type do
  @moduledoc """
  Holds the types for this library.
  """

  alias Shared.Data.{Authorization, Credentials, Order, OrderInfo, PlacedOrder, User}

  ##########
  # Types  #
  ##########

  @type item_id :: String.t()
  @type item_name :: String.t()
  @type reason :: atom()
  @type state :: %{
          dependencies: map(),
          user: User.t() | nil,
          authorization: Authorization.t() | nil
        }

  #############
  # Responses #
  #############

  @type place_order_response :: {:ok, PlacedOrder.t()} | {:error, reason, Order.t()}
  @type delete_order_response :: :ok | {:error, reason, PlacedOrder.t()}
  @type get_all_orders_response :: {:ok, [OrderInfo.t()]} | {:error, reason, item_name}
  @type login_response :: {:ok, {Authorization.t(), User.t()}} | {:error, reason, Credentials.t()}
  @type recover_login_response :: :ok
  @type logout_response :: :ok
end
