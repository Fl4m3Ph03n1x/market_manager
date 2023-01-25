defmodule AuctionHouse.Type do
  @moduledoc """
  Holds the types for this library.
  """

  alias AuctionHouse.Data.{Credentials, LoginInfo, Order, OrderInfo}

  ##########
  # Types  #
  ##########

  @type item_id :: String.t()
  @type item_name :: String.t()
  @type order_id :: String.t()
  @type reason :: atom()

  #############
  # Responses #
  #############

  @type place_order_response :: {:ok, order_id} | {:error, reason, Order.t()}
  @type delete_order_response :: {:ok, order_id} | {:error, reason, order_id}
  @type get_all_orders_response :: {:ok, [OrderInfo.t()]} | {:error, reason, item_name}
  @type login_response :: {:ok, LoginInfo.t()} | {:error, reason, Credentials.t()}
end
