defmodule AuctionHouse.Impl.GetItemOrders do
  @moduledoc """
  Requests all the sell orders for the item with the given name.
  """

  alias AuctionHouse.Type
  alias AuctionHouse.Impl.HttpAsyncClient
  alias Shared.Data.OrderInfo
  alias Jason

  @search_url Application.compile_env!(:auction_house, :api_search_url)

  @default_deps %{
    get: &HttpAsyncClient.get/4
  }

  @typep deps :: %{get: function()}
  @typep metadata :: map()
  @typep url :: String.t()

  ##########
  # Public #
  ##########

  @spec run(metadata(), deps()) :: :ok
  def run(%{item_name: item_name} = metadata, %{get: async_get} \\ @default_deps) do
    item_name
    |> build_get_orders_url()
    |> async_get.(nil, %{metadata | send?: true}, &parse_item_orders/2)
  end

  @spec parse_item_orders({HttpAsyncClient.body(), HttpAsyncClient.headers()}, metadata()) ::
          Type.get_item_orders_response()
  def parse_item_orders({body, _headers}, _metadata) do
    case Jason.decode(body) do
      {:ok, content} ->
        {:ok, parse_order_info(content)}

      err ->
        err
    end
  end

  ###########
  # Private #
  ###########

  @spec build_get_orders_url(Type.item_name()) :: url()
  defp build_get_orders_url(item_name),
    do: URI.encode(@search_url <> "/" <> Recase.to_snake(item_name) <> "/orders")

  @spec parse_order_info(orders_json :: map()) :: [OrderInfo.t()]
  defp parse_order_info(orders_json) do
    orders_json
    |> get_in(["payload", "orders"])
    |> Enum.map(&OrderInfo.new/1)
  end
end
