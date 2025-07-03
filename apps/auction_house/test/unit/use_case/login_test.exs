defmodule AuctionHouse.Impl.UseCase.LoginTest do
  @moduledoc false

  use ExUnit.Case, async: true

  alias AuctionHouse.Impl.UseCase.Login
  alias AuctionHouse.Impl.UseCase.Data.{Metadata, Request, Response}
  alias Jason
  alias Shared.Data.{Authorization, Credentials, User}

  @market_signin_url Application.compile_env!(:auction_house, :market_signin_url)
  @api_signin_url Application.compile_env!(:auction_house, :api_signin_url)

  describe "start/2" do
    test "makes request" do
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
          get: fn url, req, _next ->
            assert url == @market_signin_url
            assert req.args.credentials == request.args.credentials
            refute req.metadata.send?
            :ok
          end
        }

      assert Login.start(request, deps) == :ok
    end
  end

  describe "sign_in/2" do
    test "makes sign in request correctly" do
      credentials =
        %Credentials{
          password: "1234",
          email: "test@email.com"
        }

      authorization =
        %Authorization{
          token:
            "##2263dcc167c732ca1b54566e0c1ffb66d8e13e2ed59d113967f7fb5e119fed0f813bf7b98c9777c2f5eafd0ab5f6fdc9ad5a3a44d8b585c07ebdf0af1be310b1",
          cookie:
            "JWT=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzaWQiOiJXN2Q2UUVCTldWMGcxdklOQmdJWVJhWkNFSXZvanpnbyIsImNzcmZfdG9rZW4iOiJjZDhkZWI4MmFjNDg2ZDcwMTgyZWQzODU5OWJmMzRkNDA4NGNjNmEyIiwiZXhwIjoxNzI3Njk0MTM4LCJpYXQiOjE3MjI1MTAxMzgsImlzcyI6Imp3dCIsImF1ZCI6Imp3dCIsImF1dGhfdHlwZSI6ImNvb2tpZSJ9.uAXHKlhVE8vhFoz7uBYCqMfka7VIluYLmOiAVS7YByk"
        }

      deps =
        %{
          post: fn url, creds, req, _next, auth ->
            assert url == @api_signin_url
            assert creds == Jason.encode!(credentials)
            assert auth == authorization
            assert req.args.authorization == authorization
            assert req.metadata.send?
            :ok
          end,
          parser: &Floki.parse_document/1,
          finder: &Floki.find/2
        }

      response = %Response{
        body: """
        <!DOCTYPE html>
        <html lang=en>
        <head>
        <meta charset="UTF-8">
        <meta name="csrf-token" content="##2263dcc167c732ca1b54566e0c1ffb66d8e13e2ed59d113967f7fb5e119fed0f813bf7b98c9777c2f5eafd0ab5f6fdc9ad5a3a44d8b585c07ebdf0af1be310b1">
        <link rel="canonical" href="https://warframe.market/auth/signin">
        <link rel="alternate" hreflang="en" href="https://warframe.market/auth/signin">
        <link rel="manifest" href="/manifest.json">
        <body>
        </body>
        </script>
        </html>
        """,
        headers: %{
          "Content-Type" => "text/html; charset=utf-8",
          "Set-Cookie" =>
            "JWT=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzaWQiOiJXN2Q2UUVCTldWMGcxdklOQmdJWVJhWkNFSXZvanpnbyIsImNzcmZfdG9rZW4iOiJjZDhkZWI4MmFjNDg2ZDcwMTgyZWQzODU5OWJmMzRkNDA4NGNjNmEyIiwiZXhwIjoxNzI3Njk0MTM4LCJpYXQiOjE3MjI1MTAxMzgsImlzcyI6Imp3dCIsImF1ZCI6Imp3dCIsImF1dGhfdHlwZSI6ImNvb2tpZSJ9.uAXHKlhVE8vhFoz7uBYCqMfka7VIluYLmOiAVS7YByk; Domain=.warframe.market; Expires=Mon, 30-Sep-2024 11:02:18 GMT; Secure; HttpOnly; Path=/; SameSite=Lax"
        },
        metadata: %Metadata{
          notify: [self()],
          send?: false,
          operation: :login
        },
        request_args: %{
          credentials: credentials
        }
      }

      assert Login.sign_in(response, deps) == :ok
    end

    test "returns error if it fails to parse the body" do
      deps =
        %{
          post: fn _url, _credentials, _auth, _req, _next -> :ok end,
          parser: fn _body -> {:error, :bad_file} end
        }

      response = %Response{
        body: """
        <!DOCTYPE html>
        <html lang=en>
        <head>
        <meta charset="UTF-8">
        <meta name="csrf-token" content="##2263dcc167c732ca1b54566e0c1ffb66d8e13e2ed59d113967f7fb5e119fed0f813bf7b98c9777c2f5eafd0ab5f6fdc9ad5a3a44d8b585c07ebdf0af1be310b1">
        <link rel="canonical" href="https://warframe.market/auth/signin">
        <link rel="alternate" hreflang="en" href="https://warframe.market/auth/signin">
        <link rel="manifest" href="/manifest.json">
        <body>
        </body>
        </script>
        </html>
        """,
        headers: %{
          "Content-Type" => "text/html; charset=utf-8",
          "Set-Cookie" =>
            "JWT=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzaWQiOiJXN2Q2UUVCTldWMGcxdklOQmdJWVJhWkNFSXZvanpnbyIsImNzcmZfdG9rZW4iOiJjZDhkZWI4MmFjNDg2ZDcwMTgyZWQzODU5OWJmMzRkNDA4NGNjNmEyIiwiZXhwIjoxNzI3Njk0MTM4LCJpYXQiOjE3MjI1MTAxMzgsImlzcyI6Imp3dCIsImF1ZCI6Imp3dCIsImF1dGhfdHlwZSI6ImNvb2tpZSJ9.uAXHKlhVE8vhFoz7uBYCqMfka7VIluYLmOiAVS7YByk; Domain=.warframe.market; Expires=Mon, 30-Sep-2024 11:02:18 GMT; Secure; HttpOnly; Path=/; SameSite=Lax"
        },
        metadata: %Metadata{
          notify: [self()],
          send?: false,
          operation: :login
        },
        request_args: %{
          credentials: %Credentials{
            password: "1234",
            email: "test@email.com"
          }
        }
      }

      assert Login.sign_in(response, deps) == {:error, :bad_file}
    end

    test "returns error if it fails to find the xrfctoken" do
      deps =
        %{
          post: fn _url, _credentials, _auth, _req, _next -> :ok end,
          parser: &Floki.parse_document/1,
          finder: &Floki.find/2
        }

      response = %Response{
        body: """
        <!DOCTYPE html>
        <html lang=en>
        <head>
        <meta charset="UTF-8">
        <link rel="canonical" href="https://warframe.market/auth/signin">
        <link rel="alternate" hreflang="en" href="https://warframe.market/auth/signin">
        <link rel="manifest" href="/manifest.json">
        <body>
        </body>
        </script>
        </html>
        """,
        headers: %{
          "Content-Type" => "text/html; charset=utf-8",
          "Set-Cookie" =>
            "JWT=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzaWQiOiJXN2Q2UUVCTldWMGcxdklOQmdJWVJhWkNFSXZvanpnbyIsImNzcmZfdG9rZW4iOiJjZDhkZWI4MmFjNDg2ZDcwMTgyZWQzODU5OWJmMzRkNDA4NGNjNmEyIiwiZXhwIjoxNzI3Njk0MTM4LCJpYXQiOjE3MjI1MTAxMzgsImlzcyI6Imp3dCIsImF1ZCI6Imp3dCIsImF1dGhfdHlwZSI6ImNvb2tpZSJ9.uAXHKlhVE8vhFoz7uBYCqMfka7VIluYLmOiAVS7YByk; Domain=.warframe.market; Expires=Mon, 30-Sep-2024 11:02:18 GMT; Secure; HttpOnly; Path=/; SameSite=Lax"
        },
        metadata: %Metadata{
          notify: [self()],
          send?: false,
          operation: :login
        },
        request_args: %{
          credentials: %Credentials{
            password: "1234",
            email: "test@email.com"
          }
        }
      }

      assert Login.sign_in(response, deps) ==
               {:error,
                {:xrfc_token_not_found,
                 [
                   {"html", [{"lang", "en"}],
                    [
                      {"head", [],
                       [
                         {"meta", [{"charset", "UTF-8"}], []},
                         {"link", [{"rel", "canonical"}, {"href", "https://warframe.market/auth/signin"}], []},
                         {"link",
                          [
                            {"rel", "alternate"},
                            {"hreflang", "en"},
                            {"href", "https://warframe.market/auth/signin"}
                          ], []},
                         {"link", [{"rel", "manifest"}, {"href", "/manifest.json"}], []},
                         {"body", [], []}
                       ]}
                    ]}
                 ]}}
    end

    test "returns error if it fails to parse the cookies" do
      deps =
        %{
          post: fn _url, _credentials, _auth, _req, _next -> :ok end,
          parser: &Floki.parse_document/1,
          finder: &Floki.find/2
        }

      response = %Response{
        body: """
        <!DOCTYPE html>
        <html lang=en>
        <head>
        <meta charset="UTF-8">
        <meta name="csrf-token" content="##2263dcc167c732ca1b54566e0c1ffb66d8e13e2ed59d113967f7fb5e119fed0f813bf7b98c9777c2f5eafd0ab5f6fdc9ad5a3a44d8b585c07ebdf0af1be310b1">
        <link rel="canonical" href="https://warframe.market/auth/signin">
        <link rel="alternate" hreflang="en" href="https://warframe.market/auth/signin">
        <link rel="manifest" href="/manifest.json">
        <body>
        </body>
        </script>
        </html>
        """,
        headers: %{
          "Content-Type" => "text/html; charset=utf-8"
        },
        metadata: %Metadata{
          notify: [self()],
          send?: false,
          operation: :login
        },
        request_args: %{
          credentials: %Credentials{
            password: "1234",
            email: "test@email.com"
          }
        }
      }

      assert Login.sign_in(response, deps) ==
               {:error, {:no_cookie_found, %{"Content-Type" => "text/html; charset=utf-8"}}}
    end
  end

  describe "finish/2" do
    test "parses response correctly and returns auth and user" do
      response = %Response{
        body: """
        {"payload": {"user": {"ingame_name": "Fl4m3Ph03n1x",  "linked_accounts": {"patreon_profile": false}}}}
        """,
        headers: %{
          "Content-Type" => "application/json",
          "Set-Cookie" =>
            "JWT=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzaWQiOiJjR3ROWFUzaVR4bEg4UHh0M2pFN3NEN1kzQ3dwc0NLWCIsImNzcmZfdG9rZW4iOiIxOGQ4ZWMzODI0YzAzMjkzZjM1NjQ4OTA1OThhYjI5MDgyNWY0OTkyIiwiZXhwIjoxNzI3NzAxNDk4LCJpYXQiOjE3MjI1MTc0OTgsImlzcyI6Imp3dCIsImF1ZCI6Imp3dCIsImF1dGhfdHlwZSI6ImNvb2tpZSIsInNlY3VyZSI6dHJ1ZSwiand0X2lkZW50aXR5IjoiZXhqaGVEM1JhdVVLb0NOVUszdm11VW9kenBPT0t0bUIiLCJsb2dpbl91YSI6ImInaGFja25leS8xLjE3LjEnIiwibG9naW5faXAiOiJiJzE0Ny4xNjEuNjYuMzcnIn0.jWskOWec-x9pGtFHzB11LpUbynMMg-ARp2CgNx6VWJU; Domain=.warframe.market; Expires=Mon, 30-Sep-2024 13:04:58 GMT; Secure; HttpOnly; Path=/; SameSite=Lax"
        },
        metadata: %Metadata{
          notify: [self()],
          send?: true,
          operation: :login
        },
        request_args: %{
          credentials: %Credentials{
            password: "1234",
            email: "test@email.com"
          },
          authorization: %Authorization{
            token:
              "##2263dcc167c732ca1b54566e0c1ffb66d8e13e2ed59d113967f7fb5e119fed0f813bf7b98c9777c2f5eafd0ab5f6fdc9ad5a3a44d8b585c07ebdf0af1be310b1",
            cookie:
              "JWT=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzaWQiOiJXN2Q2UUVCTldWMGcxdklOQmdJWVJhWkNFSXZvanpnbyIsImNzcmZfdG9rZW4iOiJjZDhkZWI4MmFjNDg2ZDcwMTgyZWQzODU5OWJmMzRkNDA4NGNjNmEyIiwiZXhwIjoxNzI3Njk0MTM4LCJpYXQiOjE3MjI1MTAxMzgsImlzcyI6Imp3dCIsImF1ZCI6Imp3dCIsImF1dGhfdHlwZSI6ImNvb2tpZSJ9.uAXHKlhVE8vhFoz7uBYCqMfka7VIluYLmOiAVS7YByk"
          }
        }
      }

      assert Login.finish(response) ==
               {:ok,
                {
                  %Authorization{
                    token:
                      "##2263dcc167c732ca1b54566e0c1ffb66d8e13e2ed59d113967f7fb5e119fed0f813bf7b98c9777c2f5eafd0ab5f6fdc9ad5a3a44d8b585c07ebdf0af1be310b1",
                    cookie:
                      "JWT=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzaWQiOiJjR3ROWFUzaVR4bEg4UHh0M2pFN3NEN1kzQ3dwc0NLWCIsImNzcmZfdG9rZW4iOiIxOGQ4ZWMzODI0YzAzMjkzZjM1NjQ4OTA1OThhYjI5MDgyNWY0OTkyIiwiZXhwIjoxNzI3NzAxNDk4LCJpYXQiOjE3MjI1MTc0OTgsImlzcyI6Imp3dCIsImF1ZCI6Imp3dCIsImF1dGhfdHlwZSI6ImNvb2tpZSIsInNlY3VyZSI6dHJ1ZSwiand0X2lkZW50aXR5IjoiZXhqaGVEM1JhdVVLb0NOVUszdm11VW9kenBPT0t0bUIiLCJsb2dpbl91YSI6ImInaGFja25leS8xLjE3LjEnIiwibG9naW5faXAiOiJiJzE0Ny4xNjEuNjYuMzcnIn0.jWskOWec-x9pGtFHzB11LpUbynMMg-ARp2CgNx6VWJU"
                  },
                  %User{
                    ingame_name: "Fl4m3Ph03n1x",
                    patreon?: false
                  }
                }}
    end

    test "returns error if it fails to decode body" do
      response = %Response{
        body: """
        {hello: world}
        """,
        headers: %{
          "Content-Type" => "application/json",
          "Set-Cookie" =>
            "JWT=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzaWQiOiJjR3ROWFUzaVR4bEg4UHh0M2pFN3NEN1kzQ3dwc0NLWCIsImNzcmZfdG9rZW4iOiIxOGQ4ZWMzODI0YzAzMjkzZjM1NjQ4OTA1OThhYjI5MDgyNWY0OTkyIiwiZXhwIjoxNzI3NzAxNDk4LCJpYXQiOjE3MjI1MTc0OTgsImlzcyI6Imp3dCIsImF1ZCI6Imp3dCIsImF1dGhfdHlwZSI6ImNvb2tpZSIsInNlY3VyZSI6dHJ1ZSwiand0X2lkZW50aXR5IjoiZXhqaGVEM1JhdVVLb0NOVUszdm11VW9kenBPT0t0bUIiLCJsb2dpbl91YSI6ImInaGFja25leS8xLjE3LjEnIiwibG9naW5faXAiOiJiJzE0Ny4xNjEuNjYuMzcnIn0.jWskOWec-x9pGtFHzB11LpUbynMMg-ARp2CgNx6VWJU; Domain=.warframe.market; Expires=Mon, 30-Sep-2024 13:04:58 GMT; Secure; HttpOnly; Path=/; SameSite=Lax"
        },
        metadata: %Metadata{
          notify: [self()],
          send?: true,
          operation: :login
        },
        request_args: %{
          credentials: %Credentials{
            password: "1234",
            email: "test@email.com"
          },
          authorization: %Authorization{
            token:
              "##2263dcc167c732ca1b54566e0c1ffb66d8e13e2ed59d113967f7fb5e119fed0f813bf7b98c9777c2f5eafd0ab5f6fdc9ad5a3a44d8b585c07ebdf0af1be310b1",
            cookie:
              "JWT=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzaWQiOiJXN2Q2UUVCTldWMGcxdklOQmdJWVJhWkNFSXZvanpnbyIsImNzcmZfdG9rZW4iOiJjZDhkZWI4MmFjNDg2ZDcwMTgyZWQzODU5OWJmMzRkNDA4NGNjNmEyIiwiZXhwIjoxNzI3Njk0MTM4LCJpYXQiOjE3MjI1MTAxMzgsImlzcyI6Imp3dCIsImF1ZCI6Imp3dCIsImF1dGhfdHlwZSI6ImNvb2tpZSJ9.uAXHKlhVE8vhFoz7uBYCqMfka7VIluYLmOiAVS7YByk"
          }
        }
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
          "Content-Type" => "application/json",
          "Set-Cookie" =>
            "JWT=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzaWQiOiJjR3ROWFUzaVR4bEg4UHh0M2pFN3NEN1kzQ3dwc0NLWCIsImNzcmZfdG9rZW4iOiIxOGQ4ZWMzODI0YzAzMjkzZjM1NjQ4OTA1OThhYjI5MDgyNWY0OTkyIiwiZXhwIjoxNzI3NzAxNDk4LCJpYXQiOjE3MjI1MTc0OTgsImlzcyI6Imp3dCIsImF1ZCI6Imp3dCIsImF1dGhfdHlwZSI6ImNvb2tpZSIsInNlY3VyZSI6dHJ1ZSwiand0X2lkZW50aXR5IjoiZXhqaGVEM1JhdVVLb0NOVUszdm11VW9kenBPT0t0bUIiLCJsb2dpbl91YSI6ImInaGFja25leS8xLjE3LjEnIiwibG9naW5faXAiOiJiJzE0Ny4xNjEuNjYuMzcnIn0.jWskOWec-x9pGtFHzB11LpUbynMMg-ARp2CgNx6VWJU; Domain=.warframe.market; Expires=Mon, 30-Sep-2024 13:04:58 GMT; Secure; HttpOnly; Path=/; SameSite=Lax"
        },
        metadata: %Metadata{
          notify: [self()],
          send?: true,
          operation: :login
        },
        request_args: %{
          credentials: %Credentials{
            password: "1234",
            email: "test@email.com"
          },
          authorization: %Authorization{
            token:
              "##2263dcc167c732ca1b54566e0c1ffb66d8e13e2ed59d113967f7fb5e119fed0f813bf7b98c9777c2f5eafd0ab5f6fdc9ad5a3a44d8b585c07ebdf0af1be310b1",
            cookie:
              "JWT=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzaWQiOiJXN2Q2UUVCTldWMGcxdklOQmdJWVJhWkNFSXZvanpnbyIsImNzcmZfdG9rZW4iOiJjZDhkZWI4MmFjNDg2ZDcwMTgyZWQzODU5OWJmMzRkNDA4NGNjNmEyIiwiZXhwIjoxNzI3Njk0MTM4LCJpYXQiOjE3MjI1MTAxMzgsImlzcyI6Imp3dCIsImF1ZCI6Imp3dCIsImF1dGhfdHlwZSI6ImNvb2tpZSJ9.uAXHKlhVE8vhFoz7uBYCqMfka7VIluYLmOiAVS7YByk"
          }
        }
      }

      assert Login.finish(response) == {:error, {:payload_not_found, %{}}}
    end

    test "returns error if it fails to parse cookies" do
      response = %Response{
        body: """
        {"payload": {"user": {"ingame_name": "Fl4m3Ph03n1x",  "linked_accounts": {"patreon_profile": false}}}}
        """,
        headers: %{
          "Content-Type" => "application/json"
        },
        metadata: %Metadata{
          notify: [self()],
          send?: true,
          operation: :login
        },
        request_args: %{
          credentials: %Credentials{
            password: "1234",
            email: "test@email.com"
          },
          authorization: %Authorization{
            token:
              "##2263dcc167c732ca1b54566e0c1ffb66d8e13e2ed59d113967f7fb5e119fed0f813bf7b98c9777c2f5eafd0ab5f6fdc9ad5a3a44d8b585c07ebdf0af1be310b1",
            cookie:
              "JWT=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzaWQiOiJXN2Q2UUVCTldWMGcxdklOQmdJWVJhWkNFSXZvanpnbyIsImNzcmZfdG9rZW4iOiJjZDhkZWI4MmFjNDg2ZDcwMTgyZWQzODU5OWJmMzRkNDA4NGNjNmEyIiwiZXhwIjoxNzI3Njk0MTM4LCJpYXQiOjE3MjI1MTAxMzgsImlzcyI6Imp3dCIsImF1ZCI6Imp3dCIsImF1dGhfdHlwZSI6ImNvb2tpZSJ9.uAXHKlhVE8vhFoz7uBYCqMfka7VIluYLmOiAVS7YByk"
          }
        }
      }

      assert Login.finish(response) ==
               {:error, {:no_cookie_found, %{"Content-Type" => "application/json"}}}
    end

    test "returns error if it fails to parse ign" do
      response = %Response{
        body: """
        {"payload": {"user": {"linked_accounts": {"steam_profile": true, "patreon_profile": false, "xbox_profile": false, "discord_profile": false, "github_profile": false}}}}
        """,
        headers: %{
          "Content-Type" => "application/json",
          "Set-Cookie" =>
            "JWT=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzaWQiOiJjR3ROWFUzaVR4bEg4UHh0M2pFN3NEN1kzQ3dwc0NLWCIsImNzcmZfdG9rZW4iOiIxOGQ4ZWMzODI0YzAzMjkzZjM1NjQ4OTA1OThhYjI5MDgyNWY0OTkyIiwiZXhwIjoxNzI3NzAxNDk4LCJpYXQiOjE3MjI1MTc0OTgsImlzcyI6Imp3dCIsImF1ZCI6Imp3dCIsImF1dGhfdHlwZSI6ImNvb2tpZSIsInNlY3VyZSI6dHJ1ZSwiand0X2lkZW50aXR5IjoiZXhqaGVEM1JhdVVLb0NOVUszdm11VW9kenBPT0t0bUIiLCJsb2dpbl91YSI6ImInaGFja25leS8xLjE3LjEnIiwibG9naW5faXAiOiJiJzE0Ny4xNjEuNjYuMzcnIn0.jWskOWec-x9pGtFHzB11LpUbynMMg-ARp2CgNx6VWJU; Domain=.warframe.market; Expires=Mon, 30-Sep-2024 13:04:58 GMT; Secure; HttpOnly; Path=/; SameSite=Lax"
        },
        metadata: %Metadata{
          notify: [self()],
          send?: true,
          operation: :login
        },
        request_args: %{
          credentials: %Credentials{
            password: "1234",
            email: "test@email.com"
          },
          authorization: %Authorization{
            token:
              "##2263dcc167c732ca1b54566e0c1ffb66d8e13e2ed59d113967f7fb5e119fed0f813bf7b98c9777c2f5eafd0ab5f6fdc9ad5a3a44d8b585c07ebdf0af1be310b1",
            cookie:
              "JWT=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzaWQiOiJXN2Q2UUVCTldWMGcxdklOQmdJWVJhWkNFSXZvanpnbyIsImNzcmZfdG9rZW4iOiJjZDhkZWI4MmFjNDg2ZDcwMTgyZWQzODU5OWJmMzRkNDA4NGNjNmEyIiwiZXhwIjoxNzI3Njk0MTM4LCJpYXQiOjE3MjI1MTAxMzgsImlzcyI6Imp3dCIsImF1ZCI6Imp3dCIsImF1dGhfdHlwZSI6ImNvb2tpZSJ9.uAXHKlhVE8vhFoz7uBYCqMfka7VIluYLmOiAVS7YByk"
          }
        }
      }

      assert Login.finish(response) ==
               {:error, {:missing_ingame_name, Jason.decode!(response.body)}}
    end

    test "returns error if it fails to parse patreon" do
      response = %Response{
        body: """
        {"payload": {"user": {"ingame_name": "Fl4m3Ph03n1x",  "linked_accounts": {} }}}
        """,
        headers: %{
          "Content-Type" => "application/json",
          "Set-Cookie" =>
            "JWT=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzaWQiOiJjR3ROWFUzaVR4bEg4UHh0M2pFN3NEN1kzQ3dwc0NLWCIsImNzcmZfdG9rZW4iOiIxOGQ4ZWMzODI0YzAzMjkzZjM1NjQ4OTA1OThhYjI5MDgyNWY0OTkyIiwiZXhwIjoxNzI3NzAxNDk4LCJpYXQiOjE3MjI1MTc0OTgsImlzcyI6Imp3dCIsImF1ZCI6Imp3dCIsImF1dGhfdHlwZSI6ImNvb2tpZSIsInNlY3VyZSI6dHJ1ZSwiand0X2lkZW50aXR5IjoiZXhqaGVEM1JhdVVLb0NOVUszdm11VW9kenBPT0t0bUIiLCJsb2dpbl91YSI6ImInaGFja25leS8xLjE3LjEnIiwibG9naW5faXAiOiJiJzE0Ny4xNjEuNjYuMzcnIn0.jWskOWec-x9pGtFHzB11LpUbynMMg-ARp2CgNx6VWJU; Domain=.warframe.market; Expires=Mon, 30-Sep-2024 13:04:58 GMT; Secure; HttpOnly; Path=/; SameSite=Lax"
        },
        metadata: %Metadata{
          notify: [self()],
          send?: true,
          operation: :login
        },
        request_args: %{
          credentials: %Credentials{
            password: "1234",
            email: "test@email.com"
          },
          authorization: %Authorization{
            token:
              "##2263dcc167c732ca1b54566e0c1ffb66d8e13e2ed59d113967f7fb5e119fed0f813bf7b98c9777c2f5eafd0ab5f6fdc9ad5a3a44d8b585c07ebdf0af1be310b1",
            cookie:
              "JWT=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzaWQiOiJXN2Q2UUVCTldWMGcxdklOQmdJWVJhWkNFSXZvanpnbyIsImNzcmZfdG9rZW4iOiJjZDhkZWI4MmFjNDg2ZDcwMTgyZWQzODU5OWJmMzRkNDA4NGNjNmEyIiwiZXhwIjoxNzI3Njk0MTM4LCJpYXQiOjE3MjI1MTAxMzgsImlzcyI6Imp3dCIsImF1ZCI6Imp3dCIsImF1dGhfdHlwZSI6ImNvb2tpZSJ9.uAXHKlhVE8vhFoz7uBYCqMfka7VIluYLmOiAVS7YByk"
          }
        }
      }

      assert Login.finish(response) ==
               {:error, {:missing_patreon, Jason.decode!(response.body)}}
    end
  end
end
