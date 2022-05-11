defmodule AuctionHouse.Type do
  @moduledoc """
  Holds the types for this library.
  """

  ##########
  # Types  #
  ##########

  @type item_id :: String.t()
  @type item_name :: String.t()
  @type order_id :: String.t()

  @type order :: %{
          (item_id :: String.t()) => String.t(),
          (mod_rank :: String.t()) => non_neg_integer | String.t(),
          (order_type :: String.t()) => String.t(),
          (platinum :: String.t()) => non_neg_integer,
          (quantity :: String.t()) => pos_integer
        }

  @type order_info :: %{
          (visible :: String.t()) => boolean,
          (order_type :: String.t()) => String.t(),
          (platform :: String.t()) => String.t(),
          (platinum :: String.t()) => non_neg_integer,
          (user :: String.t()) => %{
            (ingame_name :: String.t()) => String.t(),
            (status :: String.t()) => String.t()
          }
        }

  @type credentials :: %{
          (cookie :: String.t()) => String.t(),
          (token :: String.t()) => String.t()
        }

  #############
  # Responses #
  #############

  @type place_order_response :: {:ok, order_id} | {:error, atom, order}
  @type delete_order_response :: {:ok, order_id} | {:error, atom, order_id}
  @type get_all_orders_response :: {:ok, [order_info]} | {:error, atom, item_name}
  @type update_credentials_response :: {:ok, credentials}
end
