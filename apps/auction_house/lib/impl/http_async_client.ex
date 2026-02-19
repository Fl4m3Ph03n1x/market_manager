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

  @typep parse_error ::
           :invalid_item_id
           | :invalid_email
           | :wrong_email
           | :wrong_password
           | :order_already_placed
           | :order_non_existent
           | :item_not_found
           | :slow_down
           | :internal_server_error
           | :bad_gateway
           | :server_temporary_unavailable
           | :unknown_server_error
           | :unable_to_decode_error
           | :unknown_error
           | :request_failed

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
          {:ok, HTTPoison.Response.t()} | {:error, HTTPoison.Error.t()},
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
  defp build_headers(cookie, token), do: [{"x-csrftoken", token}, {"Cookie", cookie}] ++ @static_headers

  @spec parse({:ok, HTTPoison.Response.t()} | {:error, HTTPoison.Error.t()}) ::
          {:ok, body(), headers()} | {:error, parse_error()}
  defp parse({:ok, %HTTPoison.Response{status_code: 200, body: body, headers: headers}}), do: {:ok, body, headers}

  defp parse({:ok, %HTTPoison.Response{status_code: 400 = status, body: error_body}}) do
    case Jason.decode(error_body) do
      {:ok, %{"error" => %{"inputs" => %{"itemId" => "app.field.invalid"}}}} ->
        {:error, :invalid_item_id}

      {:ok, %{"error" => %{"email" => ["app.form.invalid"]}}} ->
        {:error, :invalid_email}

      {:ok, %{"error" => %{"email" => ["app.account.email_not_exist"]}}} ->
        {:error, :wrong_email}

      {:ok, %{"error" => %{"password" => ["app.account.password_invalid"]}}} ->
        {:error, :wrong_password}

      {:error, _reason} = error ->
        Logger.error("Failed to decode error message with status #{status}: #{inspect(error)}")
        {:error, :unable_to_decode_error}
    end
  end

  defp parse({:ok, %HTTPoison.Response{status_code: 403 = status, body: error_body}}) do
    case Jason.decode(error_body) do
      {:ok, %{"error" => %{"request" => ["app.order.error.exceededOrderLimitSamePrice"]}}} ->
        {:error, :order_already_placed}

      {:error, _reason} = error ->
        Logger.error("Failed to decode error message with status #{status}: #{inspect(error)}")
        {:error, :unable_to_decode_error}
    end
  end

  defp parse({:ok, %HTTPoison.Response{status_code: 404 = status, body: error_body}}) do
    case Jason.decode(error_body) do
      {:ok, %{"error" => %{"request" => ["app.order.notFound"]}}} ->
        {:error, :order_non_existent}

      {:ok, %{"error" => %{"request" => ["app.item.notFound"]}}} ->
        {:error, :item_not_found}

      {:error, _reason} = error ->
        Logger.error("Failed to decode error message with status #{status}: #{inspect(error)}")
        {:error, :unable_to_decode_error}
    end
  end

  # warframe.market is behind CloudFlare, which will emit this error if we are making too many requests and effectively
  # block us, in order to force us to slow down.
  defp parse({:ok, %HTTPoison.Response{status_code: 429}}), do: {:error, :slow_down}

  defp parse({:ok, %HTTPoison.Response{status_code: 500}}), do: {:error, :internal_server_error}

  defp parse({:ok, %HTTPoison.Response{status_code: 502}}), do: {:error, :bad_gateway}

  defp parse({:ok, %HTTPoison.Response{status_code: 503}}), do: {:error, :server_temporary_unavailable}

  defp parse({:ok, %HTTPoison.Response{status_code: 520}}), do: {:error, :unknown_server_error}

  defp parse({:ok, %HTTPoison.Response{} = error}) do
    Logger.error("Received error with unknown format: #{inspect(error)}")
    {:error, :unknown_error}
  end

  defp parse({:error, %HTTPoison.Error{}} = error) do
    Logger.error("Failed to make request to market: #{inspect(error)}")
    {:error, :request_failed}
  end
end
