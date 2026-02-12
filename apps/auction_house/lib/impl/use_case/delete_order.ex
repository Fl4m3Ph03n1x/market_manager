defmodule AuctionHouse.Impl.UseCase.DeleteOrder do
  @moduledoc """
  Sends a delete request to the given PlacedOrder. Returns the deleted PlacedOrder if successful.
  """

  alias Shared.Data.PlacedOrder
  alias AuctionHouse.Impl.{HttpAsyncClient, UseCase}
  alias AuctionHouse.Impl.UseCase.Data.{Request, Response}
  alias Shared.Data.Authorization

  @behaviour UseCase

  @url Application.compile_env!(:auction_house, :api_order_url)

  @default_deps %{
    delete: &HttpAsyncClient.delete/4
  }

  @typep url :: String.t()
  @typep deps :: %{delete: fun()}

  ##########
  # Public #
  ##########

  @impl UseCase
  @spec start(Request.t(), deps()) :: any()
  def start(
        %Request{args: %{placed_order: placed_order, authorization: auth}} = req,
        %{delete: async_delete} \\ @default_deps
      ) do
    with :ok <- check_authorization(auth),
         url <- build_delete_url(placed_order.order_id) do
      async_delete.(
        url,
        Request.finish(req),
        &finish/1,
        auth
      )
    end
  end

  @impl UseCase
  @spec finish(Response.t()) :: {:ok, PlacedOrder.t()}
  def finish(%Response{request_args: %{placed_order: po}}), do: {:ok, po}

  ###########
  # Private #
  ###########

  @spec check_authorization(Authorization.t() | nil) :: :ok | {:error, :missing_authorization}
  defp check_authorization(%Authorization{}), do: :ok
  defp check_authorization(_auth), do: {:error, :missing_authorization}

  @spec build_delete_url(String.t()) :: url()
  defp build_delete_url(id), do: URI.encode(@url <> "/" <> id)
end
