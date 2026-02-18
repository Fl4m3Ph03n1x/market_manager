defmodule AuctionHouse.Impl.HttpAsyncClientTest do
  @moduledoc false

  use ExUnit.Case, async: false

  alias AuctionHouse.Impl.HttpAsyncClient
  alias AuctionHouse.Impl.UseCase.Data.{Metadata, Request}
  alias HTTPoison
  alias Shared.Data.Authorization

  alias AuctionHouse.Impl.HttpAsyncClientTest.{DeleteClient, GetClient1, GetClient2, PostClient}

  describe "post/6" do
    test "calls rate limiter correctly" do
      url = "www.warframe.market.com/api/v1"
      data = "{}"
      auth = %Authorization{cookie: "a_cookie", token: "token"}

      req = %Request{
        metadata: %Metadata{send?: false, notify: [], operation: :login},
        args: %{name: "John"}
      }

      response_fn = fn -> nil end

      defmodule PostLimiter do
        def make_request(request, {_, {_response_handler, original_req}} = _handler) do
          assert request ==
                   {&PostClient.post/3,
                    [
                      "www.warframe.market.com/api/v1",
                      "{}",
                      [
                        {"x-csrftoken", "token"},
                        {"Cookie", "a_cookie"},
                        {"Accept", "application/json"},
                        {"Content-Type", "application/json"}
                      ]
                    ]}

          assert original_req == %Request{
                   metadata: %Metadata{send?: false, notify: [], operation: :login},
                   args: %{name: "John"}
                 }
        end
      end

      defmodule PostClient do
        def post(_url, _data, _headers), do: {:ok, nil}
      end

      deps = %{client: PostClient, rate_limiter: PostLimiter}

      HttpAsyncClient.post(url, data, req, response_fn, auth, deps)
    end
  end

  describe "delete/3" do
    test "calls rate limiter correctly" do
      url = "www.warframe.market.com/api/v1"
      auth = %Authorization{cookie: "a_cookie", token: "token"}

      req = %Request{
        metadata: %Metadata{send?: false, notify: [], operation: :login},
        args: %{name: "John"}
      }

      response_fn = fn -> nil end

      defmodule DeleteLimiter do
        def make_request(request, {_, {_response_handler, original_req}} = _handler) do
          assert request ==
                   {&DeleteClient.delete/2,
                    [
                      "www.warframe.market.com/api/v1",
                      [
                        {"x-csrftoken", "token"},
                        {"Cookie", "a_cookie"},
                        {"Accept", "application/json"},
                        {"Content-Type", "application/json"}
                      ]
                    ]}

          assert original_req == %Request{
                   metadata: %Metadata{send?: false, notify: [], operation: :login},
                   args: %{name: "John"}
                 }
        end
      end

      defmodule DeleteClient do
        def delete(_url, _headers), do: {:ok, nil}
      end

      deps = %{client: DeleteClient, rate_limiter: DeleteLimiter}

      HttpAsyncClient.delete(url, req, response_fn, auth, deps)
    end
  end

  describe "get/3" do
    test "calls rate limiter correctly with authorization" do
      url = "www.warframe.market.com/api/v1"
      auth = %Authorization{cookie: "a_cookie", token: "token"}

      req = %Request{
        metadata: %Metadata{send?: false, notify: [], operation: :login},
        args: %{name: "John"}
      }

      response_fn = fn -> nil end

      defmodule GetLimiter1 do
        def make_request(request, {_, {_response_handler, original_req}} = _handler) do
          assert request ==
                   {&GetClient1.get/2,
                    [
                      "www.warframe.market.com/api/v1",
                      [
                        {"x-csrftoken", "token"},
                        {"Cookie", "a_cookie"},
                        {"Accept", "application/json"},
                        {"Content-Type", "application/json"}
                      ]
                    ]}

          assert original_req == %Request{
                   metadata: %Metadata{send?: false, notify: [], operation: :login},
                   args: %{name: "John"}
                 }
        end
      end

      defmodule GetClient1 do
        def get(_url, _headers), do: {:ok, nil}
      end

      deps = %{client: GetClient1, rate_limiter: GetLimiter1}

      HttpAsyncClient.get(url, req, response_fn, auth, deps)
    end

    test "calls rate limiter correctly with NO authorization" do
      url = "www.warframe.market.com/api/v1"

      req = %Request{
        metadata: %Metadata{send?: false, notify: [], operation: :login},
        args: %{name: "John"}
      }

      response_fn = fn -> nil end

      defmodule GetLimiter2 do
        def make_request(request, {_, {_response_handler, original_req}} = _handler) do
          assert request ==
                   {&GetClient2.get/2,
                    [
                      "www.warframe.market.com/api/v1",
                      [
                        {"Accept", "application/json"},
                        {"Content-Type", "application/json"}
                      ]
                    ]}

          assert original_req == %Request{
                   metadata: %Metadata{send?: false, notify: [], operation: :login},
                   args: %{name: "John"}
                 }
        end
      end

      defmodule GetClient2 do
        def get(_url, _headers), do: {:ok, nil}
      end

      deps = %{client: GetClient2, rate_limiter: GetLimiter2}

      HttpAsyncClient.get(url, req, response_fn, nil, deps)
    end
  end

  describe "handle_response" do
    test "invokes next function if response is OK" do
      pid = self()

      request = %Request{
        metadata: %Metadata{send?: false, notify: [pid], operation: :login},
        args: %{name: "John"}
      }

      response =
        {:ok,
         %HTTPoison.Response{
           status_code: 200,
           body: "{}",
           headers: [
             {"Accept", "application/json"},
             {"Content-Type", "application/json"}
           ]
         }}

      response_fn = fn _response ->
        send(pid, :response_fn_ok)
        {:ok, nil}
      end

      assert HttpAsyncClient.handle_response(response, {response_fn, request}) == :ok
      assert_received(:response_fn_ok)
      refute_received({:login, {:ok, nil}})
    end

    test "notifies interested processes if response is Error" do
      pid = self()

      request = %Request{
        metadata: %Metadata{send?: false, notify: [pid], operation: :login},
        args: %{name: "John"}
      }

      response =
        {:ok,
         %HTTPoison.Response{
           status_code: 500,
           body: "Internal error ocurred",
           headers: [
             {"Accept", "application/json"},
             {"Content-Type", "application/json"}
           ]
         }}

      response_fn = fn _response ->
        send(pid, :response_fn_ok)
        {:ok, nil}
      end

      assert HttpAsyncClient.handle_response(response, {response_fn, request}) == :ok
      refute_received(:response_fn_ok)
      assert_received({:login, {:error, :internal_server_error}})
    end

    test "notifies interested processes if response is OK and meta.send? is true" do
      pid = self()

      request = %Request{
        metadata: %Metadata{send?: true, notify: [pid], operation: :login},
        args: %{name: "John"}
      }

      response =
        {:ok,
         %HTTPoison.Response{
           status_code: 200,
           body: "{}",
           headers: [
             {"Accept", "application/json"},
             {"Content-Type", "application/json"}
           ]
         }}

      response_fn = fn _response ->
        send(pid, :response_fn_ok)
        {:ok, nil}
      end

      assert HttpAsyncClient.handle_response(response, {response_fn, request}) == :ok
      assert_received(:response_fn_ok)
      assert_received({:login, {:ok, nil}})
    end

    test "notifies interested processes if response is OK but next function errors" do
      pid = self()

      request = %Request{
        metadata: %Metadata{send?: false, notify: [pid], operation: :login},
        args: %{name: "John"}
      }

      response =
        {:ok,
         %HTTPoison.Response{
           status_code: 200,
           body: "{}",
           headers: [
             {"Accept", "application/json"},
             {"Content-Type", "application/json"}
           ]
         }}

      response_fn = fn _response ->
        send(pid, :response_fn_ok)
        {:error, :reason}
      end

      assert HttpAsyncClient.handle_response(response, {response_fn, request}) == :ok
      assert_received(:response_fn_ok)
      assert_received({:login, {:error, :reason}})
    end

    test "returns correct error for 502" do
      pid = self()

      request = %Request{
        metadata: %Metadata{send?: false, notify: [pid], operation: :login},
        args: %{name: "John"}
      }

      response =
        {:ok,
         %HTTPoison.Response{
           status_code: 502,
           body: "error code: 502",
           headers: [
             {"Date", "Tue, 31 Dec 2024 17:49:43 GMT"},
             {"Content-Type", "text/plain; charset=UTF-8"},
             {"Content-Length", "15"},
             {"Connection", "keep-alive"},
             {"Report-To",
              "{\"endpoints\":[{\"url\":\"https:\\/\\/a.nel.cloudflare.com\\/report\\/v4?s=JaQBgCwMziSjmAoxUAaLty6y0rQCmRE2Ho8RgWWIGZNQLL1Z2lSmwOV%2FcRYtiyUyOvaHZatn9en48FMbP%2BEGJAlmxdivK1hEC%2FZQBfP%2FyVp4SBp%2F8d1nQYP%2FXfpijzEDI129D5U%3D\"}],\"group\":\"cf-nel\",\"max_age\":604800}"},
             {"NEL", "{\"success_fraction\":0,\"report_to\":\"cf-nel\",\"max_age\":604800}"},
             {"Strict-Transport-Security", "max-age=2592000; includeSubDomains; preload"},
             {"X-Content-Type-Options", "nosniff"},
             {"X-Frame-Options", "SAMEORIGIN"},
             {"Referrer-Policy", "same-origin"},
             {"Cache-Control", "private, max-age=0, no-store, no-cache, must-revalidate, post-check=0, pre-check=0"},
             {"Expires", "Thu, 01 Jan 1970 00:00:01 GMT"},
             {"Server", "cloudflare"},
             {"CF-RAY", "8fac1b9ca83be060-MAD"},
             {"server-timing",
              "cfL4;desc=\"?proto=TCP&rtt=89829&min_rtt=15000&rtt_var=25476&sent=6903&recv=687&lost=0&retrans=248&sent_bytes=9418936&recv_bytes=57802&delivery_rate=359303&cwnd=1120&unsent_bytes=0&cid=b46e4764d9d94e25&ts=161181&x=0\""}
           ],
           request_url: "https://api.warframe.market/v1/profile/orders",
           request: %HTTPoison.Request{
             method: :post,
             url: "https://api.warframe.market/v1/profile/orders",
             headers: [
               {"x-csrftoken",
                "##cd456b16cc6fb4ab29717f03f2d3885126253335604d35f9d9372e0dede3731a188083b0c16e036a6d83fb5ead1f2e3c3a58e54a672d625f2243ee5b0b42eb2e"},
               {"Cookie",
                "JWT=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzaWQiOiJ1NjBPQUQ1NmhjdjcwazNGczRDcTdlbU96U1JMcEJQOCIsImNzcmZfdG9rZW4iOiI3YTM2YTQwODAwMWQ1NTJjMTYxMjc3MDVjMDQ0MTdiY2ZiMGFkODQ5IiwiZXhwIjoxNzQwODUxMjIyLCJpYXQiOjE3MzU2NjcyMjIsImlzcyI6Imp3dCIsImF1ZCI6Imp3dCIsImF1dGhfdHlwZSI6ImNvb2tpZSIsInNlY3VyZSI6dHJ1ZSwiand0X2lkZW50aXR5IjoielRDOW1WTkMza2xjWUQ3RWtkU0h1VDBYQXFucHJpTFMiLCJsb2dpbl91YSI6ImInaGFja25leS8xLjE3LjEnIiwibG9naW5faXAiOiJiJzk1LjYzLjEzNi4xNjUnIn0.3MkuESHmHNipOKwX0pAvVe9NQuCpoykhP7conHvvRac"},
               {"Accept", "application/json"},
               {"Content-Type", "application/json"}
             ],
             body:
               "{\"item_id\":\"54a74455e779892d5e5156aa\",\"order_type\":\"sell\",\"platinum\":19,\"quantity\":1,\"mod_rank\":0}",
             params: %{},
             options: []
           }
         }}

      response_fn = fn _response ->
        send(pid, :response_fn_ok)
        {:ok, nil}
      end

      assert HttpAsyncClient.handle_response(response, {response_fn, request}) == :ok
      refute_received(:response_fn_ok)
      assert_received({:login, {:error, :bad_gateway}})
    end
  end
end
