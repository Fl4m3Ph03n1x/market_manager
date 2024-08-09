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
  @type username :: String.t()
  @type reason :: atom()
  @type state :: %{
          dependencies: map(),
          user: User.t() | nil,
          authorization: Authorization.t() | nil
        }

  #############
  # Responses #
  #############

  @type place_order_response :: {:ok, PlacedOrder.t()} | {:error, any()}
  @type delete_order_response :: :ok | {:error, reason(), PlacedOrder.t()}
  @type get_item_orders_response :: {:ok, [OrderInfo.t()]} | {:error, any()}
  @type get_user_orders_response :: {:ok, [PlacedOrder.t()]} | {:error, any()}
  @type login_response ::
          {:ok, {Authorization.t(), User.t()}} | {:error, any()}
  @type recover_login_response :: :ok
  @type logout_response :: :ok
end
