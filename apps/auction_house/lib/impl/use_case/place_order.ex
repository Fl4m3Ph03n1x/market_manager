defmodule AuctionHouse.Impl.UseCase.PlaceOrder do
  @moduledoc """
  Places a sell order in the auction house and returns the result as a PlacedOrder.
  """

  alias AuctionHouse.Type
  alias AuctionHouse.Impl.{HttpAsyncClient, UseCase}
  alias AuctionHouse.Impl.UseCase.Data.{Request, Response}
  alias Shared.Data.{Authorization, PlacedOrder}
  alias Jason

  @behaviour UseCase

  @url Application.compile_env!(:auction_house, :api_base_url)

  @default_deps %{
    post: &HttpAsyncClient.post/5
  }

  ##########
  # Public #
  ##########

  @impl UseCase
  def start(
        %Request{args: %{order: order, authorization: auth}} = req,
        %{post: async_post} \\ @default_deps
      ) do
    with :ok <- check_authorization(auth),
         {:ok, order_json} <- Jason.encode(order) do
      async_post.(
        @url,
        order_json,
        auth,
        Request.finish(req),
        &finish/1
      )
    end
  end

  @impl UseCase
  @spec finish(Response.t()) :: Type.place_order_response()
  def finish(%Response{body: body, request_args: %{order: order}}) do
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
          {:ok, String.t() | Type.item_id()} | {:error, {:missing_id | :missing_order, map()}}
  defp get_id(%{"payload" => %{"order" => %{"id" => id}}}), do: {:ok, id}
  defp get_id(%{"payload" => %{"order" => _order}} = data), do: {:error, {:missing_id, data}}
  defp get_id(data), do: {:error, {:missing_order, data}}
end
