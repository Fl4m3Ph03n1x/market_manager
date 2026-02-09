defmodule AuctionHouse.Type do
  @moduledoc """
  Holds the types for this library.
  """

  alias Shared.Data.{Authorization, User}

  ##########
  # Types  #
  ##########

  @type item_id :: String.t()
  @type item_name :: String.t()
  @type username_slug :: String.t()
  @type reason :: atom()
  @type state :: %{
          user: User.t() | nil,
          authorization: Authorization.t() | nil
        }

  #############
  # Responses #
  #############

  @type place_order_response :: :ok
  @type delete_order_response :: :ok
  @type get_item_orders_response :: :ok
  @type get_user_orders_response :: :ok
  @type login_response :: :ok
  @type update_login_response :: :ok
  @type get_saved_login_response :: {:ok, {Authorization.t(), User.t()}} | {:error, any()}
  @type logout_response :: :ok
end
