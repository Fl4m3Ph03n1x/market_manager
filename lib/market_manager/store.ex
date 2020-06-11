defmodule MarketManager.Store do
  @moduledoc """
  Port for the persistency layer.
  """

  @callback get_products_from_syndicate(String.t()) ::
              {:ok, [map]}
              | {:error, any}

  @callback list_orders(String.t) :: {:ok, [String.t]}

  @callback save_order(String.t()) ::
              {:ok, :order_saved}
              | {:error, any}

  @callback delete_order(String.t()) ::
              {:ok, :order_deleted}
              | {:error, any}
end
