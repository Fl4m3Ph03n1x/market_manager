defmodule AuctionHouse.Impl.HttpAsyncClient do
  @moduledoc """

  """

  require Logger

  alias Shared.Data.{Authorization, Credentials}
  alias RateLimiter

  @http_response_timeout Application.compile_env!(:auction_house, :http_response_timeout)

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
          Authorization.t(),
          RateLimiter.metadata(),
          RateLimiter.response_function(),
          deps()
        ) :: :ok
  def post(
        url,
        data,
        %Authorization{cookie: cookie, token: token} = _auth,
        metadata,
        response_fun,
        %{rate_limiter: rate_limiter, client: client} \\ @default_deps
      ) do
    rate_limiter.make_request(
      {&client.post/4, [url, data, build_headers(cookie, token), [recv_timeout: @http_response_timeout]]},
      {&handle_response/2, {response_fun, metadata}}
    )
  end

  @spec delete(
          url(),
          Authorization.t(),
          RateLimiter.metadata(),
          RateLimiter.response_function(),
          deps()
        ) :: :ok
  def delete(
        url,
        %Authorization{cookie: cookie, token: token} = _auth,
        metadata,
        response_fun,
        %{rate_limiter: rate_limiter, client: client} \\ @default_deps
      ) do
    rate_limiter.make_request(
      {&client.delete/3, [url, build_headers(cookie, token), [recv_timeout: @http_response_timeout]]},
      {&handle_response/2, {response_fun, metadata}}
    )
  end

  @spec get(
          url(),
          Authorization.t() | nil,
          RateLimite.metadata(),
          RateLimiter.response_fun(),
          deps()
        ) :: :ok
  def get(url, auth, metadata, response_fun, deps \\ @default_deps)

  def get(
        url,
        %Authorization{cookie: cookie, token: token} = _auth,
        metadata,
        response_fun,
        %{rate_limiter: rate_limiter, client: client}
      ) do
    rate_limiter.make_request(
      {&client.get/3, [url, build_headers(cookie, token), [recv_timeout: @http_response_timeout]]},
      {&handle_response/2, {response_fun, metadata}}
    )
  end

  def get(
        url,
        nil,
        metadata,
        response_fun,
        %{rate_limiter: rate_limiter, client: client}
      ) do
    rate_limiter.make_request(
      {&client.get/3, [url, @static_headers, [recv_timeout: @http_response_timeout]]},
      {&handle_response/2, {response_fun, metadata}}
    )
  end

  def handle_response(response, {response_fun, metadata}) do
    %{from: from, send?: send?, operation: op} = metadata
    parsed_response = parse(response)

    case elem(parsed_response, 0) do
      :ok ->
        {:ok, body, headers} = parsed_response

        if send? do
          result = response_fun.({body, headers}, metadata)
          Enum.each(from, &send(&1, {op, result}))
        else
          result = response_fun.({body, headers}, metadata)

          if is_tuple(result) and elem(result, 0) == :error do
            Enum.each(from, &send(&1, {op, result}))
          end
        end

      error ->
        Enum.each(from, &send(&1, {op, parsed_response}))
    end
  end

  ###########
  # Private #
  ###########

  @spec build_headers(String.t(), String.t()) :: [{String.t(), String.t()}]
  defp build_headers(cookie, token),
    do: [{"x-csrftoken", token}, {"Cookie", cookie}] ++ @static_headers

  @spec parse({:ok, HTTPoison.Reponse.t() | {:error, HTTPoison.Error.t()}}) ::
          {:ok, body(), headers()} | {:error, reason :: any()}
  defp parse({:ok, %HTTPoison.Response{status_code: 200, body: body, headers: headers}}),
    do: {:ok, body, headers}

  defp parse({:ok, %HTTPoison.Response{status_code: status, body: error_body}})
       when status in [400, 503, 520] do
    {:error, map_error(error_body)}
  end

  defp parse({:ok, %HTTPoison.Response{status_code: 500}}) do
    {:error, :internal_server_error}
  end

  defp parse({:error, %HTTPoison.Error{id: _id, reason: reason}}),
    do: {:error, reason}

  @spec map_error(error_body :: String.t()) ::
          :invalid_item_id
          | :order_already_placed
          | :order_non_existent
          | :rank_level_non_applicable
          | :wrong_passwork
          | :wrong_email
          | :invalid_email
          | :unknown_server_error
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

  defp map_error(html) when is_binary(html) do
    Logger.error("AuctionHouse.map_error/1 received an unknown error: #{html}")
    :unknown_error
  end
end
