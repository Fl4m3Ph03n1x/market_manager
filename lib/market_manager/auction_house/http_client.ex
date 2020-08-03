defmodule MarketManager.AuctionHouse.HTTPClient do
  @moduledoc """
  Adapter for the interface AuctionHouse
  """

  use Rop

  alias MarketManager.AuctionHouse

  @behaviour AuctionHouse

  @url Application.compile_env!(:market_manager, :api_base_url)
  @search_url Application.compile_env!(:market_manager, :api_search_url)
  @cookie Application.compile_env!(:market_manager, :auction_house_cookie)
  @token Application.compile_env!(:market_manager, :auction_house_token)

  @static_headers [
    {"Accept", "application/json"},
    {"Content-Type", "application/json"}
  ]

  @default_deps [
    get_fn: &HTTPoison.get/2,
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
    |> to_auction_house_response(order, &get_id/1)

  @impl AuctionHouse
  def delete_order(order_id, deps \\ @default_deps), do:
    order_id
    |> build_delete_url()
    |> http_delete(deps[:delete_fn])
    |> to_auction_house_response(order_id, &get_id/1)

  @impl AuctionHouse
  def get_all_orders(item_name, deps \\ @default_deps), do:
    item_name
    |> Recase.to_snake()
    |> build_get_orders_url()
    |> http_get(deps[:get_fn])
    |> to_auction_house_response(item_name, &get_orders/1)

  ###########
  # Private #
  ###########

  @spec http_post(order_json :: String.t, post_fn :: function) ::
    {:ok, HTTPoison.Response.t} | {:error, HTTPoison.Error.t}
  defp http_post(order, post_fn), do: post_fn.(@url, order, headers())

  @spec http_delete(url :: String.t, delete_fun :: function) ::
    {:ok, HTTPoison.Response.t} | {:error, HTTPoison.Error.t}
  defp http_delete(url, delete_fn), do: delete_fn.(url, headers())

  @spec http_get(url :: String.t, get_fun :: function) ::
    {:ok, HTTPoison.Response.t} | {:error, HTTPoison.Error.t}
  defp http_get(url, get_fn), do: get_fn.(url, headers())

  @spec to_auction_house_response(
        {:ok, HTTPoison.Response.t} | {:error, HTTPoison.Error.t},
        AuctionHouse.order | AuctionHouse.item_id,
        success_handler_fn :: function) ::
        {:ok, AuctionHouse.order_id}
        | {:error, reason :: atom, AuctionHouse.order_id | AuctionHouse.item_id}
  defp to_auction_house_response({:ok, %HTTPoison.Response{status_code: 400, body: error_body}}, data, _handler), do:
    error_body
    |> Jason.decode()
    >>> map_error()
    |> build_error_response(data)

  defp to_auction_house_response({:ok, %HTTPoison.Response{status_code: 503, body: error_body}}, data, _handler), do:
    error_body
    |> map_error()
    |> build_error_response(data)

  defp to_auction_house_response({:ok, %HTTPoison.Response{status_code: 200, body: body}}, _data, handler), do:
    body
    |> Jason.decode()
    >>> handler.()
    |> build_success_response()

  defp to_auction_house_response({:error, %HTTPoison.Error{id: _id, reason: reason}}, data, _handler),
    do: build_error_response({:error, reason}, data)

  @spec get_orders(response :: map) :: [AuctionHouse.order_info]
  defp get_orders(%{"payload" => %{"orders" => orders}}), do: orders

  @spec map_error(error_response :: map | String.t) :: {:error,
          :invalid_item_id
          | :order_already_placed
          | :order_non_existent
          | :rank_level_non_applicable
          | :server_unavailable}
  defp map_error(%{"error" => %{"item_id" => _error}}), do: {:error, :invalid_item_id}

  defp map_error(%{"error" => %{"_form" => _error}}), do: {:error, :order_already_placed}

  defp map_error(%{"error" => %{"order_id" => _error}}), do: {:error, :order_non_existent}

  defp map_error(%{"error" => %{"mod_rank" => _error}}), do: {:error, :rank_level_non_applicable}

  defp map_error(html) when is_binary(html), do: {:error, :server_unavailable}

  @spec get_id(response :: map) :: AuctionHouse.order_id | AuctionHouse.item_id
  defp get_id(%{"payload" => %{"order" => %{"id" => id}}}), do: id
  defp get_id(%{"payload" => %{"order_id" => id}}), do: id

  @spec build_success_response(AuctionHouse.order_id | [AuctionHouse.order_info])
    :: {:ok, AuctionHouse.order_id | [AuctionHouse.order_info]}
  defp build_success_response(data), do: {:ok, data}

  @spec build_error_response({:error, reason :: atom}, AuctionHouse.order_id | AuctionHouse.order) ::
          {:error, reason :: atom, AuctionHouse.order_id | AuctionHouse.item_id}
  defp build_error_response({:error, reason}, order) when is_map(order),
    do: {:error, reason, Map.get(order, "item_id")}

  defp build_error_response({:error, reason}, order_id) when is_binary(order_id),
    do: {:error, reason, order_id}

  @spec build_delete_url(AuctionHouse.order_id) :: (url :: String.t)
  defp build_delete_url(id), do:
    URI.encode(@url <> "/" <> id)

  @spec headers :: [{String.t, String.t}]
  defp headers, do: [{"x-csrftoken", @token}, {"Cookie", @cookie}] ++ @static_headers

  @spec build_get_orders_url(item_name :: String.t) :: (uri :: String.t)
  defp build_get_orders_url(item_search_name), do:
    URI.encode(@search_url <> "/" <> item_search_name <> "/orders")

end
