defmodule AuctionHouse.Impl.Login do
  @moduledoc """
  Contains all the logic to parse and login a user asyncronously.
  """

  alias AuctionHouse.Type
  alias AuctionHouse.Impl.HttpAsyncClient
  alias Jason
  alias Shared.Data.{Authorization, User}

  @market_signin_url Application.compile_env!(:auction_house, :market_signin_url)
  @api_signin_url Application.compile_env!(:auction_house, :api_signin_url)

  @default_deps %{
    get: &HttpAsyncClient.get/4,
    post: &HttpAsyncClient.post/5,
    parser: &Floki.parse_document/1,
    finder: &Floki.find/2
  }

  @typep deps :: %{
           get: function(),
           post: function(),
           parser: function(),
           finder: function()
         }

  @typep metadata :: map()

  ##########
  # Public #
  ##########

  @spec run(metadata(), deps()) :: :ok
  def run(metadata, %{get: async_get} \\ @default_deps),
    do: async_get.(@market_signin_url, nil, metadata, &sign_in/2)

  @spec sign_in({HttpAsyncClient.body(), HttpAsyncClient.headers()}, metadata(), deps()) ::
          :ok | {:error, any()}
  def sign_in(
        {body, headers},
        %{credentials: credentials} = metadata,
        %{post: async_post, parser: parse_document} = deps \\ @default_deps
      ) do
    with {:ok, json_credentials} <- Jason.encode(credentials),
         {:ok, doc} <- parse_document.(body),
         {:ok, token} <- find_xrfc_token(doc, deps),
         {:ok, cookie} <- parse_cookie(headers),
         auth <- %Authorization{cookie: cookie, token: token} do
      async_post.(
        @api_signin_url,
        json_credentials,
        auth,
        metadata |> Map.put(:authorization, auth) |> Map.put(:send?, true),
        &parse_authorization/2
      )
    end
  end

  @spec parse_authorization({HttpAsyncClient.body(), HttpAsyncClient.headers()}, metadata()) ::
          Type.login_response()
  def parse_authorization(
        {body, headers},
        %{
          authorization: %Authorization{token: token}
        } = _metadata
      ) do
    with {:ok, decoded_body} <- validate_body(body),
         {:ok, updated_cookie} <- parse_cookie(headers),
         {:ok, ingame_name} <- parse_ingame_name(decoded_body),
         {:ok, patreon?} <- parse_patreon(decoded_body) do
      {:ok,
       {Authorization.new(%{"cookie" => updated_cookie, "token" => token}),
        User.new(%{"ingame_name" => ingame_name, "patreon?" => patreon?})}}
    end
  end

  ###########
  # Private #
  ###########

  @spec validate_body(HttpAsyncClient.body()) ::
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

  @spec find_xrfc_token(parsed_body :: [any], dependencies :: map) ::
          {:ok, String.t()} | {:error, {:xrfc_token_not_found, parsed_body :: [any]}}
  defp find_xrfc_token(doc, %{finder: find_in_document}) do
    case find_in_document.(doc, "meta[name=\"csrf-token\"]") do
      [{"meta", [{"name", "csrf-token"}, {"content", token}], []}] -> {:ok, token}
      _ -> {:error, {:xrfc_token_not_found, doc}}
    end
  end

  @spec parse_cookie(HttpAsyncClient.headers()) ::
          {:ok, String.t()}
          | {:error, {:no_cookie_found | :missing_jwt, headers :: [{String.t(), any}]}}
  defp parse_cookie(headers) do
    with {_key, val} <- List.keyfind(headers, "Set-Cookie", 0),
         [cookie | _tail] <- String.split(val, ";"),
         true <- String.contains?(cookie, "JWT=") do
      {:ok, cookie}
    else
      nil -> {:error, {:no_cookie_found, headers}}
      false -> {:error, {:missing_jwt, headers}}
      [] -> {:error, {:missing_jwt, headers}}
    end
  end

  @spec parse_patreon(body :: map) :: {:ok, boolean} | {:error, :missing_patreon, map()}
  defp parse_patreon(body) do
    case get_in(body, ["payload", "user", "linked_accounts", "patreon_profile"]) do
      nil ->
        {:error, {:missing_patreon, body}}

      patreon? ->
        {:ok, patreon?}
    end
  end

  @spec parse_ingame_name(body :: map) ::
          {:ok, String.t()} | {:error, :missing_ingame_name, map()}
  defp parse_ingame_name(body) do
    case get_in(body, ["payload", "user", "ingame_name"]) do
      nil ->
        {:error, {:missing_ingame_name, body}}

      name ->
        {:ok, name}
    end
  end
end
