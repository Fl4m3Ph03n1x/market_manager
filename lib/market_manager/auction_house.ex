defmodule MarketManager.AuctionHouse do
  @moduledoc """
  Port for http client.
  """

  @type order_id :: String.t

  @type order :: %{
    order_type: String.t,
    item_id: String.t,
    platinum: non_neg_integer,
    quantity: non_neg_integer,
    mod_rank: non_neg_integer
  }

  @callback place_order(order) ::
              {:ok, order_id}
              | {:error, :order_already_placed | :invalid_item_id, order}

  @callback delete_order(order_id) ::
              {:ok, order_id}
              | {:error, :order_non_existent, order_id}
end
