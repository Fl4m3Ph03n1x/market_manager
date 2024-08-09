defmodule AuctionHouse.Impl.PlaceOrder do
  @moduledoc """

  """

  alias AuctionHouse.Type
  alias AuctionHouse.Impl.HttpAsyncClient
  alias Shared.Data.{Authorization, Order, PlacedOrder}
  alias Jason

  @url Application.compile_env!(:auction_house, :api_base_url)

  @default_deps %{
    post: &HttpAsyncClient.post/5
  }

  @typep deps :: %{post: function()}
  @typep metadata :: map()

  ##########
  # Public #
  ##########

  @spec run(metadata(), deps()) :: :ok
  def run(%{order: order, authorization: auth} = metadata, %{post: async_post} \\ @default_deps) do
    with :ok <- check_authorization(auth),
         {:ok, order_json} <- Jason.encode(order) do
      async_post.(
        @url,
        order_json,
        auth,
        %{metadata | send?: true},
        &parse_placed_order/2
      )
    end
  end

  @spec parse_placed_order({HttpAsyncClient.body(), HttpAsyncClient.headers()}, metadata()) ::
          Type.place_order_response()
  def parse_placed_order({body, _headers}, %{order: order} = _metadata) do
    with {:ok, content} <- Jason.decode(body),
         {:ok, id} <- get_id(content) do
      {:ok, PlacedOrder.new(%{"item_id" => order.item_id, "order_id" => id})}
    end
  end

  ###########
  # Private #
  ###########

  @spec check_authorization(Authorization.t() | nil) :: :ok | {:error, :missing_authorization}
  defp check_authorization(%Authorization{}), do: :ok
  defp check_authorization(_auth), do: {:error, :missing_authorization}

  @spec get_id(response :: map) ::
          {:ok, String.t() | Type.item_id()} | {:error, {:missing_id, map()}}
  defp get_id(%{"payload" => %{"order" => %{"id" => id}}}), do: {:ok, id}
  defp get_id(%{"payload" => %{"order_id" => id}}), do: {:ok, id}
  defp get_id(data), do: {:error, :missing_id, data}
end
