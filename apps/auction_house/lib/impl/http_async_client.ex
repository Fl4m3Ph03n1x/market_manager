defmodule AuctionHouse.Impl.HttpAsyncClient do
  @moduledoc """
  Asynchronous HTTP client for the auction house. Makes requests to the auction house's API and converts errors into a
  format friendly to the application.
  Uses a rate limiter to avoid overloading the external API.
  """

  require Logger

  alias Jason
  alias Shared.Data.Authorization
  alias AuctionHouse.Impl.UseCase.Data.{Request, Response}
  alias RateLimiter

  @static_headers [
    {"Accept", "application/json"},
    {"Content-Type", "application/json"}
  ]

  @default_deps %{
    client: HTTPoison,
    rate_limiter: RateLimiter
  }

  @type url :: String.t()
  @type data :: String.t()
  @type body :: String.t()
  @type headers :: [{String.t(), String.t()}]

  @typep deps :: %{
           client: module(),
           rate_limiter: module()
         }

  ##########
  # Public #
  ##########

  @spec post(
          url(),
          data(),
          Request.t(),
          RateLimiter.response_function(),
          Authorization.t(),
          deps()
        ) :: :ok
  def post(
        url,
        data,
        request,
        response_fun,
        %Authorization{cookie: cookie, token: token},
        %{rate_limiter: rate_limiter, client: client} \\ @default_deps
      ) do
    rate_limiter.make_request(
      {&client.post/3, [url, data, build_headers(cookie, token)]},
      {&handle_response/2, {response_fun, request}}
    )
  end

  @spec delete(
          url(),
          Request.t(),
          RateLimiter.response_function(),
          Authorization.t(),
          deps()
        ) :: :ok
  def delete(
        url,
        request,
        response_fun,
        %Authorization{cookie: cookie, token: token},
        %{rate_limiter: rate_limiter, client: client} \\ @default_deps
      ) do
    rate_limiter.make_request(
      {&client.delete/2, [url, build_headers(cookie, token)]},
      {&handle_response/2, {response_fun, request}}
    )
  end

  @spec get(
          url(),
          Request.t(),
          RateLimiter.response_function(),
          Authorization.t() | nil,
          deps()
        ) :: :ok
  def get(url, request, response_fun, auth \\ nil, deps \\ @default_deps)

  def get(
        url,
        request,
        response_fun,
        %Authorization{cookie: cookie, token: token},
        %{rate_limiter: rate_limiter, client: client}
      ) do
    rate_limiter.make_request(
      {&client.get/2, [url, build_headers(cookie, token)]},
      {&handle_response/2, {response_fun, request}}
    )
  end

  def get(
        url,
        request,
        response_fun,
        nil,
        %{rate_limiter: rate_limiter, client: client}
      ) do
    rate_limiter.make_request(
      {&client.get/2, [url, @static_headers]},
      {&handle_response/2, {response_fun, request}}
    )
  end

  @spec handle_response(
          {:ok, HTTPoison.Response.t() | {:error, HTTPoison.Error.t()}},
          {(... -> any()), Request.t()}
        ) :: :ok
  def handle_response(response, {response_fun, %Request{metadata: meta, args: args}}) do
    parsed_response = parse(response)

    case elem(parsed_response, 0) do
      :ok ->
        {:ok, body, headers} = parsed_response

        headers_map = Enum.reduce(headers, %{}, fn {key, val}, acc -> Map.put(acc, key, val) end)

        response = Response.new(meta, body, headers_map, args)
        result = response_fun.(response)

        if meta.send? or (is_tuple(result) and elem(result, 0) == :error) do
          Enum.each(meta.notify, &send(&1, {meta.operation, result}))
        end

      :error ->
        Enum.each(meta.notify, &send(&1, {meta.operation, parsed_response}))
    end

    :ok
  end

  ###########
  # Private #
  ###########

  @spec build_headers(String.t(), String.t()) :: [{String.t(), String.t()}]
  defp build_headers(cookie, token),
    do: [{"x-csrftoken", token}, {"Cookie", cookie}] ++ @static_headers

  @spec parse({:ok, HTTPoison.Response.t() | {:error, HTTPoison.Error.t()}}) ::
          {:ok, body(), headers()} | {:error, reason :: any()}
  defp parse({:ok, %HTTPoison.Response{status_code: 200, body: body, headers: headers}}),
    do: {:ok, body, headers}

  defp parse({:ok, %HTTPoison.Response{status_code: status, body: error_body}})
       when status in [400, 404, 429, 503, 520] do
    {:error, map_error(error_body)}
  end

  defp parse({:ok, %HTTPoison.Response{status_code: 500}}), do: {:error, :internal_server_error}

  defp parse({:error, %HTTPoison.Error{id: _id, reason: reason}}), do: {:error, reason}

  @spec map_error(body()) ::
          :invalid_item_id
          | :order_already_placed
          | :order_non_existent
          | :rank_level_non_applicable
          | :wrong_password
          | :wrong_email
          | :invalid_email
          | :unknown_server_error
          | :slow_down
          | :url_not_found
          | :unknown_error
          | :unknown_format_error
  defp map_error(~s({"error": {"item_id": ["app.form.invalid"]}})), do: :invalid_item_id

  defp map_error(~s({"error": {"_form": ["app.post_order.already_created_no_duplicates"]}})),
    do: :order_already_placed

  defp map_error(~s({"error": {"order_id": ["app.delete_order.order_not_exist"]}})),
    do: :order_non_existent

  defp map_error(~s({"error": {"rank": ["app.form.invalid"]}})),
    do: :rank_level_non_applicable

  defp map_error(~s({"error": {"password": ["app.account.password_invalid"]}})),
    do: :wrong_password

  defp map_error(~s({"error": {"email": ["app.account.email_not_exist"]}})),
    do: :wrong_email

  defp map_error(~s({"error": {"email": ["app.form.invalid"]}})), do: :invalid_email

  defp map_error("error code: 520"), do: :unknown_server_error

  # warframe.market is behind CloudFlare, which will emit this error if we are making too many requests and effectively
  # block us, in order to force us to slow down.
  defp map_error("error code: 1015"), do: :slow_down

  defp map_error(error_body) when is_binary(error_body) do
    case Jason.decode(error_body) do
      {:ok, %{"error" => reason}} when is_binary(reason) ->
        if valid_uri?(reason) do
          Logger.error("URL not found. Please review the API: #{error_body}")
          :url_not_found
        else
          Logger.error("AuctionHouse.map_error/1 received an unknown error: #{error_body}")
          :unknown_error
        end

      {:ok, _reason} ->
        Logger.error("AuctionHouse.map_error/1 received error with unknown format error: #{error_body}")
        :unknown_format_error

      {:error, _reason} = error ->
        Logger.error("Failed to decode error message: #{inspect(error)}")
    end
  end

  @spec valid_uri?(url()) :: boolean()
  defp valid_uri?(url) do
    uri = URI.parse(url)

    uri.scheme == "https" and uri.host =~ "api.warframe.market" and uri.authority =~ "api.warframe.market" and
      uri.port == 443 and (uri.path =~ "GET" or uri.path =~ "POST")
  end
end
