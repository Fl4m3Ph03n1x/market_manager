defmodule AuctionHouse.Impl.HTTPClient do
  @moduledoc """
  Adapter for the interface AuctionHouse
  """

  require Logger

  alias AuctionHouse.Data.{Credentials, LoginInfo, Order, OrderInfo}
  alias AuctionHouse.Type

  @url Application.compile_env!(:auction_house, :api_base_url)
  @search_url Application.compile_env!(:auction_house, :api_search_url)
  @market_signin_url Application.compile_env!(:auction_house, :market_signin_url)
  @api_signin_url Application.compile_env!(:auction_house, :api_signin_url)

  @static_headers [
    {"Accept", "application/json"},
    {"Content-Type", "application/json"}
  ]

  ##########
  # Public #
  ##########

  @spec place_order(Order.t(), deps :: map) :: Type.place_order_response()
  def place_order(order, deps) do
    with :ok <- check_authorization(deps),
         {:ok, order_json} <- Jason.encode(order),
         {:ok, %HTTPoison.Response{status_code: 200, body: body}} <- http_post(order_json, deps),
         {:ok, content} <- Jason.decode(body),
         {:ok, id} <- get_id(content) do
      {:ok, id}
    else
      error -> to_auction_house_error(error, order)
    end
  end

  @spec delete_order(Type.order_id(), deps :: map) :: Type.delete_order_response()
  def delete_order(order_id, deps) do
    with :ok <- check_authorization(deps),
         url <- build_delete_url(order_id),
         {:ok, %HTTPoison.Response{status_code: 200, body: body}} <- http_delete(url, deps),
         {:ok, content} <- Jason.decode(body),
         {:ok, id} <- get_id(content) do
      {:ok, id}
    else
      error -> to_auction_house_error(error, order_id)
    end
  end

  @spec get_all_orders(Type.item_name(), deps :: map) :: Type.get_all_orders_response()
  def get_all_orders(item_name, deps) do
    with urls <- build_get_orders_url(item_name),
         {:ok, %HTTPoison.Response{status_code: 200, body: body}} <- http_get(urls, deps),
         {:ok, content} <- Jason.decode(body) do
      {:ok, parse_order_info(content)}
    else
      error -> to_auction_house_error(error, item_name)
    end
  end

  @spec login(Credentials.t(), deps :: map) :: {:ok, LoginInfo.t()} | {:error, any}
  def login(
        credentials,
        %{post_fn: post} = deps
      ) do
    with {:ok, json_credentials} <- Jason.encode(credentials),
         {:ok, token: token, cookie: cookie} <- fetch_authentication_data(deps),
         {:ok, %HTTPoison.Response{status_code: 200, body: body, headers: headers}} <-
           post.(@api_signin_url, json_credentials, build_headers(cookie, token)),
         {:ok, decoded_body} <- validate_body(body),
         {:ok, updated_cookie} <- parse_cookie(headers) do
      {:ok, LoginInfo.new(updated_cookie, token, get_patreon(decoded_body))}
    else
      error -> to_auction_house_error(error, credentials)
    end
  end

  ###########
  # Private #
  ###########

  @spec check_authorization(deps :: map) :: boolean
  defp check_authorization(%{authorization: %LoginInfo{}}), do: :ok
  defp check_authorization(_deps), do: {:error, :missing_authorization_credentials}

  @spec fetch_authentication_data(deps :: map) ::
          {:ok, [token: String.t(), cookie: String.t()]} | {:error, any}
  defp fetch_authentication_data(
         %{
           parse_document_fn: parse_document,
           get_fn: get
         } = deps
       ) do
    with {:ok, %HTTPoison.Response{status_code: 200, body: body, headers: headers}} <-
           get.(@market_signin_url, @static_headers),
         {:ok, doc} <- parse_document.(body),
         {:ok, token} <- find_xrfc_token(doc, deps),
         {:ok, cookie} <- parse_cookie(headers) do
      {:ok, token: token, cookie: cookie}
    end
  end

  @spec validate_body(body :: String.t()) ::
          {:ok, map}
          | {:error, {:payload_not_found, map} | {:unable_to_decode_body, Jason.DecodeError.t()}}
  defp validate_body(body) do
    case Jason.decode(body) do
      {:ok, decoded_body} ->
        if is_nil(Map.get(decoded_body, "payload")) do
          {:error, {:payload_not_found, decoded_body}}
        else
          {:ok, decoded_body}
        end

      {:error, %Jason.DecodeError{} = err} ->
        {:error, {:unable_to_decode_body, err}}
    end
  end

  @spec find_xrfc_token(parsed_body :: [any], deps :: map) ::
          {:ok, String.t()} | {:erorr, {:xrfc_token_not_found, parsed_body :: [any]}}
  defp find_xrfc_token(doc, %{find_in_document_fn: find_in_document}) do
    case find_in_document.(doc, "meta[name=\"csrf-token\"]") do
      [{"meta", [{"name", "csrf-token"}, {"content", token}], []}] -> {:ok, token}
      _ -> {:error, {:xrfc_token_not_found, doc}}
    end
  end

  @spec parse_cookie(headers :: [{String.t(), any}]) ::
          {:ok, String.t()}
          | {:error, {:no_cookie_found | :missing_jwt, headers :: [{String.t(), any}]}}
  defp parse_cookie(headers) do
    with {_key, val} <- List.keyfind(headers, "set-cookie", 0),
         [cookie | _tail] <- String.split(val, ";"),
         true <- String.contains?(cookie, "JWT=") do
      {:ok, cookie}
    else
      nil -> {:error, {:no_cookie_found, headers}}
      false -> {:error, {:missing_jwt, headers}}
      [] -> {:error, {:missing_jwt, headers}}
    end
  end

  @spec get_patreon(body :: map) :: boolean
  defp get_patreon(body) do
    get_in(body, ["payload", "user", "linked_accounts", "patreon_profile"]) || false
  end

  @spec http_post(order_json :: String.t(), deps :: map) ::
          {:ok, HTTPoison.Response.t()} | {:error, HTTPoison.Error.t()}
  defp http_post(order, %{
         post_fn: post,
         run_fn: run,
         requests_queue: queue,
         authorization: %LoginInfo{cookie: cookie, token: token}
       }),
       do: run.(queue, fn -> post.(@url, order, build_headers(cookie, token)) end)

  @spec http_delete(url :: String.t(), deps :: map) ::
          {:ok, HTTPoison.Response.t()} | {:error, HTTPoison.Error.t()}
  defp http_delete(url, %{
         delete_fn: delete,
         run_fn: run,
         requests_queue: queue,
         authorization: %LoginInfo{cookie: cookie, token: token}
       }),
       do: run.(queue, fn -> delete.(url, build_headers(cookie, token)) end)

  @spec http_get(url :: String.t(), deps :: map) ::
          {:ok, HTTPoison.Response.t()} | {:error, HTTPoison.Error.t()}
  defp http_get(url, %{
         get_fn: get,
         run_fn: run,
         requests_queue: queue,
         authorization: %LoginInfo{cookie: cookie, token: token}
       }),
       do: run.(queue, fn -> get.(url, build_headers(cookie, token)) end)

  defp http_get(url, %{
         get_fn: get,
         run_fn: run,
         requests_queue: queue
       }),
       do: run.(queue, fn -> get.(url, @static_headers) end)

  defp to_auction_house_error(
         {:ok, %HTTPoison.Response{status_code: 400, body: error_body}},
         data
       ) do
    error_body
    |> map_error()
    |> build_error_response(data)
  end

  defp to_auction_house_error(
         {:ok, %HTTPoison.Response{status_code: 500}},
         data
       ) do
    build_error_response({:error, :internal_server_error}, data)
  end

  defp to_auction_house_error(
         {:ok, %HTTPoison.Response{status_code: 503, body: error_body}},
         data
       ),
       do:
         error_body
         |> map_error()
         |> build_error_response(data)

  defp to_auction_house_error(
         {:error, %HTTPoison.Error{id: _id, reason: reason}},
         data
       ),
       do: build_error_response({:error, reason}, data)

  defp to_auction_house_error({:error, reason}, data),
    do: {:error, reason, data}

  @spec parse_order_info(orders_json :: [map()]) :: [OrderInfo.t()]
  defp parse_order_info(orders_json) do
    orders_json
    |> get_in(["payload", "orders"])
    |> Enum.map(&OrderInfo.new/1)
  end

  @spec map_error(error_response :: String.t()) ::
          {:error,
           :invalid_item_id
           | :order_already_placed
           | :order_non_existent
           | :rank_level_non_applicable
           | :server_unavailable}
  defp map_error(~s({"error":{"item_id":["app.form.invalid"]}})),
    do: {:error, :invalid_item_id}

  defp map_error(~s({"error":{"_form":["app.post_order.already_created_no_duplicates"]}})),
    do: {:error, :order_already_placed}

  defp map_error(~s({"error": {"order_id": ["app.form.invalid"]}})),
    do: {:error, :order_non_existent}

  defp map_error(~s({"error":{"mod_rank":["app.form.invalid"]}})),
    do: {:error, :rank_level_non_applicable}

  defp map_error(~s({"error": {"password": ["app.account.password_invalid"]}})),
    do: {:error, :wrong_password}

  defp map_error(html) when is_binary(html), do: {:error, :server_unavailable}

  @spec get_id(response :: map) ::
          {:ok, Type.order_id() | Type.item_id()} | {:error, {:missing_id, map()}}
  defp get_id(%{"payload" => %{"order" => %{"id" => id}}}), do: {:ok, id}
  defp get_id(%{"payload" => %{"order_id" => id}}), do: {:ok, id}
  defp get_id(data), do: {:error, :missing_id, data}

  @spec build_error_response({:error, reason :: atom}, any) ::
          {:error, reason :: atom, any}
  defp build_error_response({:error, reason}, data),
    do: {:error, reason, data}

  @spec build_delete_url(Type.order_id()) :: uri :: String.t()
  defp build_delete_url(id), do: URI.encode(@url <> "/" <> id)

  @spec build_headers(String.t(), String.t()) :: [{String.t(), String.t()}]
  defp build_headers(cookie, token),
    do: [{"x-csrftoken", token}, {"Cookie", cookie}] ++ @static_headers

  @spec build_get_orders_url(item_name :: String.t()) :: uri :: String.t()
  defp build_get_orders_url(item_name),
    do: URI.encode(@search_url <> "/" <> Recase.to_snake(item_name) <> "/orders")
end
