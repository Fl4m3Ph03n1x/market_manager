defmodule AuctionHouse.Impl.UseCase.Login do
  @moduledoc """
  Contains all the logic to parse and login a user asynchronously.
  """

  alias AuctionHouse.Impl.{HttpAsyncClient, UseCase}
  alias AuctionHouse.Impl.UseCase.Data.{Request, Response}
  alias Jason
  alias Shared.Data.{Authorization, User}

  @behaviour UseCase

  @api_signin_url Application.compile_env!(:auction_house, :api_signin_url)

  @signin_headers [{"Authorization", "JWT"}]

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
  def start(%Request{args: %{credentials: credentials}} = request, %{post: async_post} \\ @default_deps) do
    with {:ok, signin_body} <-
           credentials |> Map.from_struct() |> Map.put(:auth_type, "header") |> Jason.encode() do
      async_post.(@api_signin_url, signin_body, Request.finish(request), &finish/1, @signin_headers)
    end
  end

  @impl UseCase
  @spec finish(Response.t()) ::
          {:error,
           {:missing_token, Response.headers()}
           | {:invalid_token_format, Response.headers()}
           | {:payload_not_found, map()}
           | {:unable_to_decode_body, Jason.DecodeError.t()}}
          | {:ok, {Authorization.t(), User.t()}}
  def finish(%Response{body: body, headers: headers}) do
    with {:ok, decoded_body} <- validate_body(body),
         {:ok, access_token} <- parse_access_token(headers),
         {:ok, ingame_name} <- parse_ingame_name(decoded_body),
         {:ok, slug} <- parse_slug(decoded_body),
         {:ok, patreon?} <- parse_patreon(decoded_body) do
      {:ok,
       {Authorization.new(%{"access_token" => access_token}),
        User.new(%{"ingame_name" => ingame_name, "slug" => slug, "patreon?" => patreon?})}}
    end
  end

  ###########
  # Private #
  ###########

  @spec validate_body(HttpAsyncClient.body()) ::
          {:ok, body()}
          | {:error, {:payload_not_found, body()} | {:unable_to_decode_body, Jason.DecodeError.t()}}
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

  @spec parse_access_token(Response.headers()) ::
          {:ok, String.t()} | {:error, {:missing_token | :invalid_token_format, Response.headers()}}
  defp parse_access_token(%{"authorization" => "JWT " <> access_token}) when access_token != "",
    do: {:ok, access_token}

  defp parse_access_token(%{"authorization" => _value} = headers),
    do: {:error, {:invalid_token_format, obfuscate(headers)}}

  defp parse_access_token(headers), do: {:error, {:missing_token, obfuscate(headers)}}

  # error tuples can end up in logs, so they must not expose tokens
  @spec obfuscate(Response.headers()) :: Response.headers()
  defp obfuscate(headers), do: Map.new(headers, fn {name, value} -> {name, obfuscate(name, value)} end)

  @spec obfuscate(String.t(), String.t()) :: String.t()
  defp obfuscate("authorization", value) do
    case String.split(value, " ", parts: 2) do
      [scheme, _credentials] -> scheme <> " [REDACTED]"
      [_no_scheme] -> "[REDACTED]"
    end
  end

  defp obfuscate("set-cookie", value) do
    case String.split(value, "=", parts: 2) do
      [cookie_name, _cookie_value] -> cookie_name <> "=[REDACTED]"
      [_no_name] -> "[REDACTED]"
    end
  end

  defp obfuscate(_name, value), do: value

  @spec parse_patreon(body()) :: {:ok, boolean} | {:error, :missing_patreon, body()}
  defp parse_patreon(body) do
    case get_in(body, ["payload", "user", "linked_accounts", "patreon_profile"]) do
      nil ->
        {:error, {:missing_patreon, body}}

      patreon? ->
        {:ok, patreon?}
    end
  end

  @spec parse_ingame_name(body()) :: {:ok, String.t()} | {:error, :missing_ingame_name, body()}
  defp parse_ingame_name(body) do
    case get_in(body, ["payload", "user", "ingame_name"]) do
      nil ->
        {:error, {:missing_ingame_name, body}}

      name ->
        {:ok, name}
    end
  end

  @spec parse_slug(body()) :: {:ok, String.t()} | {:error, :missing_slug, body()}
  defp parse_slug(body) do
    case get_in(body, ["payload", "user", "slug"]) do
      nil ->
        {:error, {:missing_slug, body}}

      slug ->
        {:ok, slug}
    end
  end
end
