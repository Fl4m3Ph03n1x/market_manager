defmodule MarketManager.AuctionHouse.HTTPClient do
  @moduledoc """
  Adapter for the interface AuctionHouse
  """

  use Rop

  alias MarketManager.AuctionHouse

  @behaviour AuctionHouse

  @url Application.compile_env!(:market_manager, :api_base_url)
  @cookie Application.compile_env!(:market_manager, :auction_house_cookie)
  @token Application.compile_env!(:market_manager, :auction_house_token)

  @static_headers [
    {"Accept", "application/json"},
    {"Content-Type", "application/json"}
  ]

  @default_deps [
    post_fn: &HTTPoison.post/3,
    delete_fn: &HTTPoison.delete/2
  ]

  ##########
  # Public #
  ##########

  @impl AuctionHouse
  def place_order(order, deps \\ @default_deps), do:
    Jason.encode(order)
    >>> http_post(deps[:post_fn])
    |> to_auction_house_response(order)

  @impl AuctionHouse
  def delete_order(order_id, deps \\ @default_deps), do:
    order_id
    |> build_delete_url()
    |> http_delete(deps[:delete_fn])
    |> to_auction_house_response(order_id)

  ###########
  # Private #
  ###########

  @spec http_post(order_json :: String.t, post_fn :: function) ::
    {:ok, HTTPoison.Response.t} | {:error, HTTPoison.Error.t}
  defp http_post(order, post_fn), do: post_fn.(@url, order, headers())

  @spec http_delete(url :: String.t, delete_fun :: function) ::
    {:ok, HTTPoison.Response.t} | {:error, HTTPoison.Error.t}
  defp http_delete(url, delete_fn), do: delete_fn.(url, headers())

  @spec to_auction_house_response(
        {:ok, HTTPoison.Response.t} | {:error, HTTPoison.Error.t},
        AuctionHouse.order | AuctionHouse.item_id) ::
        {:ok, AuctionHouse.order_id}
        | {:error, reason :: atom, AuctionHouse.order_id | AuctionHouse.item_id}
  defp to_auction_house_response({:ok, %HTTPoison.Response{status_code: 400, body: error_body}}, order), do:
    error_body
    |> Jason.decode()
    >>> map_error()
    |> build_error_response(order)

  defp to_auction_house_response({:ok, %HTTPoison.Response{status_code: 200, body: body}}, _order), do:
    body
    |> Jason.decode()
    >>> get_id()
    |> build_success_response()

  defp to_auction_house_response({:error, %HTTPoison.Error{id: _id, reason: reason}}, order),
    do: build_error_response({:error, reason}, order)

  @spec map_error(error_response :: map) :: {:error,
          :invalid_item_id
          | :order_already_placed
          | :order_non_existent
          | :rank_level_non_applicable}
  defp map_error(%{"error" => %{"item_id" => _error}}), do: {:error, :invalid_item_id}

  defp map_error(%{"error" => %{"_form" => _error}}), do: {:error, :order_already_placed}

  defp map_error(%{"error" => %{"order_id" => _error}}), do: {:error, :order_non_existent}

  defp map_error(%{"error" => %{"mod_rank" => _error}}), do: {:error, :rank_level_non_applicable}

  @spec get_id(response :: map) :: AuctionHouse.order_id | AuctionHouse.item_id
  defp get_id(%{"payload" => %{"order" => %{"id" => id}}}), do: id
  defp get_id(%{"payload" => %{"order_id" => id}}), do: id

  @spec build_success_response(AuctionHouse.order_id) :: {:ok, AuctionHouse.order_id}
  defp build_success_response(id), do: {:ok, id}

  @spec build_error_response({:error, reason :: atom}, AuctionHouse.order_id | AuctionHouse.order) ::
          {:error, reason :: atom, AuctionHouse.order_id | AuctionHouse.item_id}
  defp build_error_response({:error, reason}, order) when is_map(order),
    do: {:error, reason, Map.get(order, "item_id")}

  defp build_error_response({:error, reason}, order_id) when is_binary(order_id),
    do: {:error, reason, order_id}

  @spec build_delete_url(AuctionHouse.order_id) :: (url :: String.t)
  defp build_delete_url(id), do: @url <> "/" <> id

  def headers, do: [{"x-csrftoken", @token}, {"Cookie", @cookie}] ++ @static_headers

end
