defmodule MarketManager.AuctionHouse do
  @moduledoc """
  Port for http client.
  """

  @type item_id :: String.t()
  @type order_id :: String.t()
  @type deps :: keyword

  @type order :: %{
          (item_id :: String.t()) => String.t(),
          (name :: String.t()) => String.t(),
          (price :: String.t()) => non_neg_integer,
          (quantity :: String.t()) => non_neg_integer,
          (rank :: String.t()) => non_neg_integer | String.t()
        }

  @callback place_order(order) ::
              {:ok, order_id}
              | {:error, :order_already_placed | :invalid_item_id, order}
  @callback place_order(order, deps) ::
              {:ok, order_id}
              | {:error, :order_already_placed | :invalid_item_id, order}

  @callback delete_order(order_id) ::
              {:ok, order_id}
              | {:error, :order_non_existent | :timeout, order_id}
  @callback delete_order(order_id, deps) ::
              {:ok, order_id}
              | {:error, :order_non_existent | :timeout, order_id}
end
