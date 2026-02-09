defmodule AuctionHouse.Impl.UseCase.GetItemOrders do
  @moduledoc """
  Requests all the sell orders for the item with the given name.
  """

  alias AuctionHouse.Impl.{HttpAsyncClient, UseCase}
  alias AuctionHouse.Impl.UseCase.Data.{Request, Response}
  alias AuctionHouse.Type
  alias Jason
  alias Shared.Data.OrderInfo

  @behaviour UseCase

  @item_orders_url Application.compile_env!(:auction_house, :api_item_orders_url)

  @default_deps %{
    get: &HttpAsyncClient.get/3
  }

  @typep url :: String.t()
  @typep deps :: %{get: fun()}

  ##########
  # Public #
  ##########

  @impl UseCase
  @spec start(Request.t(), deps()) :: any()
  def start(%Request{args: %{item_name: item_name}} = req, %{get: async_get} \\ @default_deps) do
    item_name
    |> build_get_orders_url()
    |> async_get.(Request.finish(req), &finish/1)
  end

  @impl UseCase
  @spec finish(Response.t()) :: {:ok, Type.item_name(), [OrderInfo.t()]} | {:error, Type.item_name(), any()}
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
  defp build_get_orders_url(item_name) do
    slug_name =
      item_name
      |> Recase.to_snake()
      |> String.downcase()

    URI.encode(@item_orders_url <> "/" <> slug_name)
  end

  @spec parse_order_info(orders_json :: map()) :: [OrderInfo.t()]
  defp parse_order_info(orders_json) do
    orders_json
    |> Map.get("data")
    |> Enum.map(&OrderInfo.new/1)
  end
end
