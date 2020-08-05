defmodule AuctionHouse do
  @moduledoc """
  Port for http client.
  """

  alias AuctionHouse.HTTPClient

  ##########
  # Types  #
  ##########

  @type item_id :: String.t
  @type item_name :: String.t
  @type order_id :: String.t
  @type deps :: keyword

  @type order :: %{
    (item_id :: String.t) => String.t,
    (mod_rank :: String.t) => non_neg_integer | String.t,
    (order_type :: String.t) => String.t,
    (platinum :: String.t) => non_neg_integer,
    (quantity :: String.t) => non_neg_integer
  }

  @type order_info :: %{
    (visible :: String.t) => boolean,
    (order_type :: String.t) => String.t,
    (platform :: String.t) => String.t,
    (platinum :: String.t) => non_neg_integer,
    (user :: String.t) => %{
      (ingame_name :: String.t) => String.t,
      (status :: String.t) => String.t
    }
  }

  #############
  # Responses #
  #############

  @type place_order_response :: {:ok, order_id} | {:error, atom, order}
  @type delete_order_response :: {:ok, order_id} | {:error, atom, order_id}
  @type get_all_orders_response :: {:ok, [order_info]} | {:error, atom, item_name}

  #############
  # Callbacks #
  #############

  @callback place_order(order) :: place_order_response
  @callback place_order(order, deps) :: place_order_response
  @spec place_order(binary | %{optional(binary) => binary}) ::
          {:ok, binary} | {:error, atom, binary}
  defdelegate place_order(order), to: HTTPClient

  @callback delete_order(order_id) :: delete_order_response
  @callback delete_order(order_id, deps) :: delete_order_response
  defdelegate delete_order(order_id), to: HTTPClient

  @callback get_all_orders(item_name) :: get_all_orders_response
  @callback get_all_orders(item_name, deps) :: get_all_orders_response
  defdelegate get_all_orders(item_name), to: HTTPClient
end
