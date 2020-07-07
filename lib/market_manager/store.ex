defmodule MarketManager.Store do
  @moduledoc """
  Port for the persistency layer.
  """

  @type order_id :: String.t()
  @type syndicate :: String.t()
  @type deps :: keyword()

  @callback list_products(syndicate) :: {:ok, [map]} | {:error, :syndicate_not_found, syndicate_name :: String.t} | {:error, any}
  @callback list_products(syndicate, deps) :: {:ok, [map]} | {:error, :syndicate_not_found, syndicate_name :: String.t} |{:error, any}

  @callback list_orders(syndicate) :: {:ok, [order_id]} | {:error, :syndicate_not_found, syndicate_name :: String.t} | {:error, any}
  @callback list_orders(syndicate, deps) :: {:ok, [order_id]} | {:error, :syndicate_not_found, syndicate_name :: String.t} | {:error, any}

  @callback save_order(order_id, syndicate) ::
              {:ok, order_id}
              | {:error, any}
  @callback save_order(order_id, syndicate, deps) ::
              {:ok, order_id}
              | {:error, any}

  @callback delete_order(order_id, syndicate) ::
              {:ok, order_id}
              | {:error, any}
  @callback delete_order(order_id, syndicate, deps) ::
              {:ok, order_id}
              | {:error, any}
end
