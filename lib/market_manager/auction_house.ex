defmodule MarketManager.AuctionHouse do
  @moduledoc """
  Port for http client.
  """

  @type order_id :: String.t()
  @type deps :: keyword

  @type order :: %{
          String.t() => String.t(),
          String.t() => String.t(),
          String.t() => non_neg_integer,
          String.t() => non_neg_integer,
          String.t() => non_neg_integer
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
