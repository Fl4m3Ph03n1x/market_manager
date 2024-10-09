defmodule AuctionHouse.Impl.UseCase.GetItemOrders do
  @moduledoc """
  Requests all the sell orders for the item with the given name.
  """

  alias AuctionHouse.Type
  alias AuctionHouse.Impl.{HttpAsyncClient, UseCase}
  alias AuctionHouse.Impl.UseCase.Data.{Request, Response}
  alias Shared.Data.OrderInfo
  alias Jason

  @behaviour UseCase

  @search_url Application.compile_env!(:auction_house, :api_search_url)

  @default_deps %{
    get: &HttpAsyncClient.get/3
  }

  @typep url :: String.t()

  ##########
  # Public #
  ##########

  @impl UseCase
  def start(%Request{args: %{item_name: item_name}} = req, %{get: async_get} \\ @default_deps) do
    item_name
    |> build_get_orders_url()
    |> async_get.(Request.finish(req), &finish/1)
  end

  @impl UseCase
  @spec finish(Response.t()) :: Type.get_item_orders_response()
  def finish(%Response{body: body, request_args: %{item_name: item_name}}) do
    case Jason.decode(body) do
      {:ok, content} ->
        {:ok, item_name, parse_order_info(content)}

      {:error, reason} ->
        {:error, item_name, reason}
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
