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

  @api_profile_url Application.compile_env!(:auction_house, :api_profile_url)

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
  def start(%Request{args: %{username: username}} = request, %{get: async_get} \\ @default_deps) do
    username
    |> build_user_orders_url()
    |> async_get.(Request.finish(request), &finish/1)
  end

  @impl UseCase
  @spec finish(Response.t()) :: {:ok, [PlacedOrder.t()]} | {:error, Jason.DecodeError.t()}
  def finish(%Response{body: body}) do
    case Jason.decode(body) do
      {:ok, content} ->
        {:ok, parse_user_order_info(content)}

      err ->
        err
    end
  end

  ###########
  # Private #
  ###########

  @spec build_user_orders_url(Type.username()) :: url()
  defp build_user_orders_url(username),
    do: URI.encode(@api_profile_url <> "/" <> username <> "/orders")

  @spec parse_user_order_info(orders_json :: map()) :: [PlacedOrder.t()]
  defp parse_user_order_info(orders_json) do
    orders_json
    |> get_in(["payload", "sell_orders"])
    |> Enum.map(&to_placed_order/1)
    |> Enum.map(&PlacedOrder.new/1)
  end

  @spec to_placed_order(map()) :: map()
  defp to_placed_order(user_orders) do
    order_id = Map.get(user_orders, "id")
    item_id = get_in(user_orders, ["item", "id"])

    user_orders
    |> Map.put("order_id", order_id)
    |> Map.put("item_id", item_id)
  end
end
