defmodule AuctionHouse.Impl.DeleteOrder do
  @moduledoc """

  """

  alias AuctionHouse.Type
  alias AuctionHouse.Impl.HttpAsyncClient
  alias Shared.Data.{Authorization, PlacedOrder}

  @url Application.compile_env!(:auction_house, :api_base_url)

  @default_deps %{
    delete: &HttpAsyncClient.delete/4
  }

  @typep deps :: %{post: function()}
  @typep metadata :: map()
  @typep url :: String.t()

  ##########
  # Public #
  ##########

  @spec run(metadata(), deps()) :: :ok
  def run(
        %{placed_order: placed_order, authorization: auth} = metadata,
        %{delete: async_delete} \\ @default_deps
      ) do
    with :ok <- check_authorization(auth),
         url <- build_delete_url(placed_order.order_id) do
      async_delete.(
        url,
        auth,
        %{metadata | send?: true},
        &order_deleted/2
      )
    end
  end

  @spec order_deleted({HttpAsyncClient.body(), HttpAsyncClient.headers()}, metadata()) ::
          {:ok, PlacedOrder.t()}
  def order_deleted(_response, %{placed_order: po} = _metadata), do: {:ok, po}

  ###########
  # Private #
  ###########

  @spec check_authorization(Authorization.t() | nil) :: :ok | {:error, :missing_authorization}
  defp check_authorization(%Authorization{}), do: :ok
  defp check_authorization(_auth), do: {:error, :missing_authorization}

  @spec build_delete_url(String.t()) :: url()
  defp build_delete_url(id), do: URI.encode(@url <> "/" <> id)
end
