defmodule MarketManager.AuctionHouse do
  @moduledoc """
  Port for http client.
  """

  ##########
  # Types  #
  ##########

  @type item_id :: String.t
  @type order_id :: String.t
  @type deps :: keyword
  @type order :: %{
          (item_id :: String.t) => String.t,
          (name :: String.t) => String.t,
          (price :: String.t) => non_neg_integer,
          (quantity :: String.t) => non_neg_integer,
          (rank :: String.t) => non_neg_integer | String.t
        }

  #############
  # Responses #
  #############

  @type place_order_response :: {:ok, order_id} | {:error, atom, order}
  @type delete_order_response :: {:ok, order_id} | {:error, atom, order_id}

  #############
  # Callbacks #
  #############

  @callback place_order(order) :: place_order_response
  @callback place_order(order, deps) :: place_order_response

  @callback delete_order(order_id) :: delete_order_response
  @callback delete_order(order_id, deps) :: delete_order_response
end
