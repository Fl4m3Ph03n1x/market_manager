defmodule AuctionHouse.Impl.UseCase.Login do
  @moduledoc """
  Contains all the logic to parse and login a user asynchronously.
  """

  alias AuctionHouse.Impl.{HttpAsyncClient, UseCase}
  alias AuctionHouse.Impl.UseCase.Data.{Metadata, Request, Response}
  alias Jason
  alias Shared.Data.{Authorization, User}

  @behaviour UseCase

  @market_signin_url Application.compile_env!(:auction_house, :market_signin_url)
  @api_signin_url Application.compile_env!(:auction_house, :api_signin_url)

  @default_deps %{
    get: &HttpAsyncClient.get/3,
    post: &HttpAsyncClient.post/5,
    parser: &Floki.parse_document/1,
    finder: &Floki.find/2
  }

  @typep deps :: %{
           get: fun(),
           post: fun(),
           finder: fun(),
           parser: fun()
         }
  @typep parsed_body :: [String.t()]
  @typep body :: map()
  @typep cookie :: String.t()

  ##########
  # Public #
  ##########

  @impl UseCase
  @spec start(Request.t(), deps()) :: any()
  def start(request, %{get: async_get} \\ @default_deps) do
    async_get.(@market_signin_url, request, &sign_in/1)
  end

  @spec sign_in(Response.t(), deps()) :: :ok | {:error, any()}
  def sign_in(
        %Response{
          metadata: meta,
          body: body,
          headers: headers,
          request_args: %{credentials: credentials}
        },
        %{post: async_post, parser: parse_document} = deps \\ @default_deps
      ) do
    with {:ok, json_credentials} <- Jason.encode(credentials),
         {:ok, doc} <- parse_document.(body),
         {:ok, token} <- find_xrfc_token(doc, deps),
         {:ok, cookie} <- parse_cookie(headers),
         auth <- %Authorization{cookie: cookie, token: token} do
      request =
        meta
        |> Metadata.mark_to_send()
        |> Request.new()
        |> Request.put_arg(:authorization, auth)

      async_post.(
        @api_signin_url,
        json_credentials,
        request,
        &finish/1,
        auth
      )
    end
  end

  @impl UseCase
  @spec finish(Response.t()) ::
          {:error,
           {:missing_jwt, map()}
           | {:no_cookie_found, map()}
           | {:payload_not_found, map()}
           | {:unable_to_decode_body, Jason.DecodeError.t()}}
          | {:ok, {Authorization.t(), User.t()}}
  def finish(%Response{
        body: body,
        headers: headers,
        request_args: %{authorization: %Authorization{token: token}}
      }) do
    with {:ok, decoded_body} <- validate_body(body),
         {:ok, updated_cookie} <- parse_cookie(headers),
         {:ok, ingame_name} <- parse_ingame_name(decoded_body),
         {:ok, slug} <- parse_slug(decoded_body),
         {:ok, patreon?} <- parse_patreon(decoded_body) do
      {:ok,
       {Authorization.new(%{"cookie" => updated_cookie, "token" => token}),
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

  @spec find_xrfc_token(parsed_body(), deps()) ::
          {:ok, String.t()} | {:error, {:xrfc_token_not_found, parsed_body()}}
  defp find_xrfc_token(doc, %{finder: find_in_document}) do
    case find_in_document.(doc, "meta[name=\"csrf-token\"]") do
      [{"meta", [{"name", "csrf-token"}, {"content", token}], []}] -> {:ok, token}
      _ -> {:error, {:xrfc_token_not_found, doc}}
    end
  end

  @spec parse_cookie(Response.headers()) ::
          {:ok, cookie()} | {:error, {:no_cookie_found | :missing_jwt, Response.headers()}}
  defp parse_cookie(%{"Set-Cookie" => val} = headers) do
    with [cookie | _tail] <- String.split(val, ";"),
         true <- String.contains?(cookie, "JWT=") do
      {:ok, cookie}
    else
      false -> {:error, {:missing_jwt, headers}}
      [] -> {:error, {:missing_jwt, headers}}
    end
  end

  defp parse_cookie(headers), do: {:error, {:no_cookie_found, headers}}

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
