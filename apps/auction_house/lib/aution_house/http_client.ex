defmodule AuctionHouse.HTTPClient do
  @moduledoc """
  Adapter for the interface AuctionHouse
  """

  use Rop

  alias AuctionHouse.Type

  @url Application.compile_env!(:auction_house, :api_base_url)
  @search_url Application.compile_env!(:auction_house, :api_search_url)

  @static_headers [
    {"Accept", "application/json"},
    {"Content-Type", "application/json"}
  ]

  ##########
  # Public #
  ##########

  def place_order(order, deps), do:
    order
    |> Jason.encode()
    >>> http_post(deps)
    |> to_auction_house_response(order, &get_id/1)

  def delete_order(order_id, deps), do:
    order_id
    |> build_delete_url()
    |> http_delete(deps)
    |> to_auction_house_response(order_id, &get_id/1)

  def get_all_orders(item_name, deps), do:
    item_name
    |> Recase.to_snake()
    |> build_get_orders_url()
    |> http_get(deps)
    |> to_auction_house_response(item_name, &get_orders/1)

  ###########
  # Private #
  ###########

  @spec http_post(order_json :: String.t, deps :: map) ::
    {:ok, HTTPoison.Response.t} | {:error, HTTPoison.Error.t}
  defp http_post(order, %{post_fn: post, run_fn: run, requests_queue: queue, cookie: cookie, token: token}), do:
    run.(queue, fn -> post.(@url, order, build_hearders(cookie, token)) end)

  @spec http_delete(url :: String.t, deps :: map) ::
    {:ok, HTTPoison.Response.t} | {:error, HTTPoison.Error.t}
  defp http_delete(url, %{delete_fn: delete, run_fn: run, requests_queue: queue, cookie: cookie, token: token}), do:
    run.(queue, fn -> delete.(url, build_hearders(cookie, token)) end)

  @spec http_get(url :: String.t, deps :: map) ::
    {:ok, HTTPoison.Response.t} | {:error, HTTPoison.Error.t}
  defp http_get(url, %{get_fn: get, run_fn: run, requests_queue: queue, cookie: cookie, token: token}), do:
    run.(queue, fn -> get.(url, build_hearders(cookie, token)) end)

  @spec to_auction_house_response(
        {:ok, HTTPoison.Response.t} | {:error, HTTPoison.Error.t},
        Type.order | Type.item_id,
        success_handler_fn :: function) ::
        {:ok, Type.order_id}
        | {:error, reason :: atom, Type.order_id | Type.item_id}
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

  @spec get_orders(response :: map) :: [Type.order_info]
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

  @spec get_id(response :: map) :: Type.order_id | Type.item_id
  defp get_id(%{"payload" => %{"order" => %{"id" => id}}}), do: id
  defp get_id(%{"payload" => %{"order_id" => id}}), do: id

  @spec build_success_response(Type.order_id | [Type.order_info])
    :: {:ok, Type.order_id | [Type.order_info]}
  defp build_success_response(data), do: {:ok, data}

  @spec build_error_response({:error, reason :: atom}, Type.order_id | Type.order) ::
          {:error, reason :: atom, Type.order_id | Type.item_id}
  defp build_error_response({:error, reason}, order) when is_map(order),
    do: {:error, reason, Map.get(order, "item_id")}

  defp build_error_response({:error, reason}, order_id) when is_binary(order_id),
    do: {:error, reason, order_id}

  @spec build_delete_url(Type.order_id) :: (url :: String.t)
  defp build_delete_url(id), do:
    URI.encode(@url <> "/" <> id)

  @spec build_hearders(String.t, String.t) :: [{String.t, String.t}]
  defp build_hearders(cookie, token), do: [{"x-csrftoken", token}, {"Cookie", cookie}] ++ @static_headers

  @spec build_get_orders_url(item_name :: String.t) :: (uri :: String.t)
  defp build_get_orders_url(item_search_name), do:
    URI.encode(@search_url <> "/" <> item_search_name <> "/orders")

end
