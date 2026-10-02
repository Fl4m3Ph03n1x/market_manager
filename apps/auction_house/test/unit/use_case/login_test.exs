defmodule AuctionHouse.Impl.UseCase.LoginTest do
  @moduledoc false

  use ExUnit.Case, async: true

  alias AuctionHouse.Impl.UseCase.Data.{Metadata, Request, Response}
  alias AuctionHouse.Impl.UseCase.Login
  alias Jason
  alias Shared.Data.{Authorization, Credentials, User}

  @api_signin_url Application.compile_env!(:auction_house, :api_signin_url)

  describe "start/2" do
    test "makes a header-based sign in request" do
      request = %Request{
        metadata: %Metadata{
          notify: [self()],
          operation: :login,
          send?: false
        },
        args: %{
          credentials: %Credentials{email: "test@email.com", password: "1234"}
        }
      }

      deps =
        %{
          post: fn url, body, req, _next, headers ->
            assert url == @api_signin_url

            assert Jason.decode!(body) == %{
                     "email" => "test@email.com",
                     "password" => "1234",
                     "auth_type" => "header"
                   }

            assert req.metadata.send?
            assert headers == [{"Authorization", "JWT"}]
            :ok
          end
        }

      assert Login.start(request, deps) == :ok
    end
  end

  describe "finish/2" do
    test "parses response correctly and returns auth and user" do
      response = %Response{
        body: """
        {"payload": {"user": {"ingame_name": "Fl4m3Ph03n1x", "slug": "fl4m3ph03n1x", "linked_accounts": {"patreon_profile": false}}}}
        """,
        headers: %{
          "content-type" => "application/json",
          "authorization" => "JWT a_token"
        },
        metadata: %Metadata{
          notify: [self()],
          send?: true,
          operation: :login
        },
        request_args: %{}
      }

      assert Login.finish(response) ==
               {:ok,
                {
                  %Authorization{access_token: "a_token"},
                  %User{
                    ingame_name: "Fl4m3Ph03n1x",
                    slug: "fl4m3ph03n1x",
                    patreon?: false
                  }
                }}
    end

    test "returns error with redacted cookie if the authorization header is missing" do
      response = %Response{
        body: """
        {"payload": {"user": {"ingame_name": "Fl4m3Ph03n1x", "slug": "fl4m3ph03n1x", "linked_accounts": {"patreon_profile": false}}}}
        """,
        headers: %{
          "content-type" => "application/json",
          "set-cookie" => "JWT=a_token; Domain=.warframe.market; Secure; HttpOnly; Path=/"
        },
        metadata: %Metadata{
          notify: [self()],
          send?: true,
          operation: :login
        },
        request_args: %{}
      }

      assert Login.finish(response) ==
               {:error,
                {:missing_token, %{"content-type" => "application/json", "set-cookie" => "JWT=[REDACTED]"}}}
    end

    test "returns error with redacted token if the authorization scheme is not JWT" do
      response = %Response{
        body: """
        {"payload": {"user": {"ingame_name": "Fl4m3Ph03n1x", "slug": "fl4m3ph03n1x", "linked_accounts": {"patreon_profile": false}}}}
        """,
        headers: %{
          "content-type" => "application/json",
          "authorization" => "Bearer a_token"
        },
        metadata: %Metadata{
          notify: [self()],
          send?: true,
          operation: :login
        },
        request_args: %{}
      }

      assert Login.finish(response) ==
               {:error,
                {:invalid_token_format,
                 %{"content-type" => "application/json", "authorization" => "Bearer [REDACTED]"}}}
    end

    test "returns error if the JWT token is empty" do
      response = %Response{
        body: """
        {"payload": {"user": {"ingame_name": "Fl4m3Ph03n1x", "slug": "fl4m3ph03n1x", "linked_accounts": {"patreon_profile": false}}}}
        """,
        headers: %{
          "content-type" => "application/json",
          "authorization" => "JWT "
        },
        metadata: %Metadata{
          notify: [self()],
          send?: true,
          operation: :login
        },
        request_args: %{}
      }

      assert Login.finish(response) ==
               {:error,
                {:invalid_token_format, %{"content-type" => "application/json", "authorization" => "JWT [REDACTED]"}}}
    end

    test "returns error with fully redacted value if the authorization header has no scheme" do
      response = %Response{
        body: """
        {"payload": {"user": {"ingame_name": "Fl4m3Ph03n1x", "slug": "fl4m3ph03n1x", "linked_accounts": {"patreon_profile": false}}}}
        """,
        headers: %{
          "content-type" => "application/json",
          "authorization" => "a_token"
        },
        metadata: %Metadata{
          notify: [self()],
          send?: true,
          operation: :login
        },
        request_args: %{}
      }

      assert Login.finish(response) ==
               {:error,
                {:invalid_token_format, %{"content-type" => "application/json", "authorization" => "[REDACTED]"}}}
    end

    test "returns error if it fails to decode body" do
      response = %Response{
        body: """
        {hello: world}
        """,
        headers: %{
          "content-type" => "application/json",
          "authorization" => "JWT a_token"
        },
        metadata: %Metadata{
          notify: [self()],
          send?: true,
          operation: :login
        },
        request_args: %{}
      }

      assert Login.finish(response) ==
               {:error, {:unable_to_decode_body, %Jason.DecodeError{position: 1, token: nil, data: "{hello: world}\n"}}}
    end

    test "returns error if it fails to payload is missing from body" do
      response = %Response{
        body: """
        {}
        """,
        headers: %{
          "content-type" => "application/json",
          "authorization" => "JWT a_token"
        },
        metadata: %Metadata{
          notify: [self()],
          send?: true,
          operation: :login
        },
        request_args: %{}
      }

      assert Login.finish(response) == {:error, {:payload_not_found, %{}}}
    end

    test "returns error if it fails to parse ign" do
      response = %Response{
        body: """
        {"payload": {"user": {"linked_accounts": {"steam_profile": true, "patreon_profile": false, "xbox_profile": false, "discord_profile": false, "github_profile": false}}}}
        """,
        headers: %{
          "content-type" => "application/json",
          "authorization" => "JWT a_token"
        },
        metadata: %Metadata{
          notify: [self()],
          send?: true,
          operation: :login
        },
        request_args: %{}
      }

      assert Login.finish(response) ==
               {:error, {:missing_ingame_name, Jason.decode!(response.body)}}
    end

    test "returns error if it fails to parse patreon" do
      response = %Response{
        body: """
        {"payload": {"user": {"ingame_name": "Fl4m3Ph03n1x", "slug": "fl4m3ph03n1x", "linked_accounts": {} }}}
        """,
        headers: %{
          "content-type" => "application/json",
          "authorization" => "JWT a_token"
        },
        metadata: %Metadata{
          notify: [self()],
          send?: true,
          operation: :login
        },
        request_args: %{}
      }

      assert Login.finish(response) ==
               {:error, {:missing_patreon, Jason.decode!(response.body)}}
    end

    test "returns error if it fails to parse slug" do
      response = %Response{
        body: """
        {"payload": {"user": {"ingame_name": "Fl4m3Ph03n1x", "patreon_profile": true, "linked_accounts": {} }}}
        """,
        headers: %{
          "content-type" => "application/json",
          "authorization" => "JWT a_token"
        },
        metadata: %Metadata{
          notify: [self()],
          send?: true,
          operation: :login
        },
        request_args: %{}
      }

      assert Login.finish(response) ==
               {:error, {:missing_slug, Jason.decode!(response.body)}}
    end
  end
end
