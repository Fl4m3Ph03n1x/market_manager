defmodule MarketManager.AuctionHouse do
  @moduledoc """
  Port for http client.
  """

  @callback place_order() :: :ok

  @callback delete_order() :: :ok
end
