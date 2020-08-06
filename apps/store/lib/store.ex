defmodule Store do
  @moduledoc """
  Port for the persistency layer.
  """

  alias Store.FileSystem

  ##########
  # Types  #
  ##########

  @type order_id :: String.t
  @type syndicate :: String.t
  @type deps :: keyword
  @type product :: %{
    (name :: String.t()) => String.t(),
    (id :: String.t()) => String.t(),
    (price :: String.t()) => non_neg_integer,
    (quantity :: String.t()) => non_neg_integer,
    (rank :: String.t()) => non_neg_integer | String.t()
  }
  @type all_orders_store :: %{
    (new_loka :: String.t()) => [order_id],
    (perrin_sequence :: String.t()) => [order_id],
    (red_veil :: String.t()) => [order_id],
    (simaris :: String.t()) => [order_id]
  }

  #############
  # Responses #
  #############

  @type list_products_response :: {:ok, [product]} | {:error, any}
  @type list_orders_response :: {:ok, [order_id]} | {:error, any}
  @type save_order_response :: {:ok, order_id} | {:error, any}
  @type delete_order_response :: {:ok, order_id} | {:error, any}

  #############
  # Callbacks #
  #############

  @callback list_products(syndicate) :: list_products_response
  @callback list_products(syndicate, deps) :: list_products_response
  defdelegate list_products(syndicate), to: FileSystem

  @callback list_orders(syndicate) :: list_orders_response
  @callback list_orders(syndicate, deps) :: list_orders_response
  defdelegate list_orders(syndicate), to: FileSystem

  @callback save_order(order_id, syndicate) :: save_order_response
  @callback save_order(order_id, syndicate, deps) :: save_order_response
  defdelegate save_order(order_id, syndicate), to: FileSystem

  @callback delete_order(order_id, syndicate) :: delete_order_response
  @callback delete_order(order_id, syndicate, deps) :: delete_order_response
  defdelegate delete_order(order_id, syndicate), to: FileSystem
end
