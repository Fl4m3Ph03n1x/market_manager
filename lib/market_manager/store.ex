defmodule MarketManager.Store do
  @moduledoc """
  Port for the persistency layer.
  """

  @type order_id :: String.t()
  @type syndicate :: String.t()

  @callback get_products_from_syndicate(syndicate) ::
              {:ok, [map]}
              | {:error, any}

  @callback list_orders(syndicate) :: {:ok, [order_id]}

  @callback save_order(order_id, syndicate) ::
              {:ok, order_id}
              | {:error, any}

  @callback delete_order(order_id, syndicate) ::
              {:ok, order_id}
              | {:error, any}
end
