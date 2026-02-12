defmodule AuctionHouse.Impl.UseCase.GetUserOrders do
  @moduledoc """
  Requests all the orders from the user with the given username and parses them.
  """

  alias AuctionHouse.Type
  alias AuctionHouse.Impl.{HttpAsyncClient, UseCase}
  alias AuctionHouse.Impl.UseCase.Data.{Request, Response}
  alias Jason
  alias Shared.Data.PlacedOrder

  @behaviour UseCase

  @api_user_orders_url Application.compile_env!(:auction_house, :api_user_orders_url)

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
  def start(%Request{args: %{username_slug: username_slug}} = request, %{get: async_get} \\ @default_deps) do
    username_slug
    |> build_user_orders_url()
    |> async_get.(Request.finish(request), &finish/1)
  end

  @impl UseCase
  @spec finish(Response.t()) :: {:ok, [PlacedOrder.t()]} | {:error, Jason.DecodeError.t()}
  def finish(%Response{body: body}) do
    with {:ok, content} <- Jason.decode(body) do
      {:ok, parse_user_order_info(content)}
    end
  end

  ###########
  # Private #
  ###########

  @spec build_user_orders_url(Type.username_slug()) :: url()
  defp build_user_orders_url(username_slug),
    do: URI.encode(@api_user_orders_url <> "/" <> username_slug)

  @spec parse_user_order_info(orders_json :: map()) :: [PlacedOrder.t()]
  defp parse_user_order_info(orders_json) do
    orders_json
    |> Map.get("data")
    |> Enum.map(&to_placed_order/1)
    |> Enum.map(&PlacedOrder.new/1)
  end

  @spec to_placed_order(map()) :: PlacedOrder.placed_order()
  defp to_placed_order(order), do: [order_id: Map.get(order, "id"), item_id: Map.get(order, "itemId")]
end
