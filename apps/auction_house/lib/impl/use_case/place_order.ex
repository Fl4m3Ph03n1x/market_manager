defmodule AuctionHouse.Impl.UseCase.PlaceOrder do
  @moduledoc """
  Places a sell order in the auction house and returns the result as a PlacedOrder.
  """

  alias AuctionHouse.Impl.{HttpAsyncClient, UseCase}
  alias AuctionHouse.Impl.UseCase.Data.{Request, Response}
  alias AuctionHouse.Type
  alias Jason
  alias Shared.Data.{Authorization, PlacedOrder}

  @behaviour UseCase

  @url Application.compile_env!(:auction_house, :api_order_url)

  @default_deps %{
    post: &HttpAsyncClient.post/5
  }

  @typep deps :: %{post: fun()}
  @typep body :: map()

  ##########
  # Public #
  ##########

  @impl UseCase
  @spec start(Request.t(), deps()) :: any()
  def start(
        %Request{args: %{order: order, authorization: auth}} = req,
        %{post: async_post} \\ @default_deps
      ) do
    with :ok <- check_authorization(auth),
         {:ok, order_json} <- Jason.encode(order) do
      async_post.(
        @url,
        order_json,
        Request.finish(req),
        &finish/1,
        auth
      )
    end
  end

  @impl UseCase
  @spec finish(Response.t()) ::
          {:error, {:missing_id, body()} | {:missing_order, body()} | Jason.DecodeError.t()}
          | {:ok, PlacedOrder.t()}
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

  @spec get_id(body()) :: {:ok, String.t() | Type.item_id()} | {:error, {:missing_order, body()}}
  defp get_id(%{"data" => %{"id" => id}}), do: {:ok, id}
  defp get_id(data), do: {:error, {:missing_order, data}}
end
