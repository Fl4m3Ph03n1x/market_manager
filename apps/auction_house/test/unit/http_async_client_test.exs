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

          assert original_req.metadata == %Metadata{send?: false, notify: [], operation: :login}
          assert original_req.args.name == "John"
          assert original_req.args.retries == 0

          assert original_req.args.call ==
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

          :ok
        end
      end

      defmodule PostClient do
        def post(_url, _data, _headers), do: {:ok, nil}
      end

      deps = %{client: PostClient, rate_limiter: PostLimiter}

      assert HttpAsyncClient.post(url, data, req, response_fn, auth, deps) == :ok
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

          assert original_req.metadata == %Metadata{send?: false, notify: [], operation: :login}
          assert original_req.args.name == "John"
          assert original_req.args.retries == 0

          assert original_req.args.call ==
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

          :ok
        end
      end

      defmodule DeleteClient do
        def delete(_url, _headers), do: {:ok, nil}
      end

      deps = %{client: DeleteClient, rate_limiter: DeleteLimiter}

      assert HttpAsyncClient.delete(url, req, response_fn, auth, deps) == :ok
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

          assert original_req.metadata == %Metadata{send?: false, notify: [], operation: :login}
          assert original_req.args.name == "John"
          assert original_req.args.retries == 0

          assert original_req.args.call ==
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

          :ok
        end
      end

      defmodule GetClient1 do
        def get(_url, _headers), do: {:ok, nil}
      end

      assert HttpAsyncClient.get(url, req, response_fn, auth, %{client: GetClient1, rate_limiter: GetLimiter1}) == :ok
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

          assert original_req.metadata == %Metadata{send?: false, notify: [], operation: :login}
          assert original_req.args.name == "John"

          assert original_req.args.call ==
                   {&GetClient2.get/2,
                    [
                      "www.warframe.market.com/api/v1",
                      [{"Accept", "application/json"}, {"Content-Type", "application/json"}]
                    ]}

          assert original_req.args.retries == 0
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
        args: %{
          name: "John",
          call:
            {nil,
             [
               "REQUEST_URL",
               [
                 {"Accept", "application/json"},
                 {"Content-Type", "application/json"}
               ]
             ]},
          retries: 0
        }
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
        args: %{
          name: "John",
          call:
            {nil,
             [
               "REQUEST_URL",
               [
                 {"Accept", "application/json"},
                 {"Content-Type", "application/json"}
               ]
             ]},
          retries: 3
        }
      }

      response =
        {:ok,
         %HTTPoison.Response{
           status_code: 500,
           body: "Internal error occurred",
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
        args: %{
          name: "John",
          call:
            {nil,
             [
               "REQUEST_URL",
               [
                 {"Accept", "application/json"},
                 {"Content-Type", "application/json"}
               ]
             ]},
          retries: 0
        }
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
        args: %{
          name: "John",
          call:
            {nil,
             [
               "REQUEST_URL",
               [
                 {"Accept", "application/json"},
                 {"Content-Type", "application/json"}
               ]
             ]},
          retries: 0
        }
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

    test "returns correct 400 error for non-existing itemId" do
      pid = self()

      request = %Request{
        metadata: %Metadata{send?: false, notify: [pid], operation: :place_order},
        args: %{
          name: "John",
          call:
            {nil,
             [
               "REQUEST_URL",
               [
                 {"Accept", "application/json"},
                 {"Content-Type", "application/json"}
               ]
             ]},
          retries: 0
        }
      }

      response =
        {:ok,
         %HTTPoison.Response{
           status_code: 400,
           body:
             "{\"apiVersion\":\"0.22.7\",\"data\":null,\"error\":{\"inputs\":{\"itemId\":\"app.field.invalid\"}}}\n",
           headers: [
             {"Date", "Thu, 19 Feb 2026 14:27:18 GMT"},
             {"Content-Type", "application/json"},
             {"Content-Length", "86"},
             {"Connection", "keep-alive"},
             {"Server", "cloudflare"},
             {"strict-transport-security", "max-age=2592000; includeSubDomains; preload"},
             {"cf-cache-status", "DYNAMIC"},
             {"Nel", "{\"report_to\":\"cf-nel\",\"success_fraction\":0.0,\"max_age\":604800}"},
             {"X-Content-Type-Options", "nosniff"},
             {"Report-To",
              "{\"group\":\"cf-nel\",\"max_age\":604800,\"endpoints\":[{\"url\":\"https://a.nel.cloudflare.com/report/v4?s=jM1W3UQCzzzAONX%2B0tLzwGjfhgauYohMDQqfcW9VlGFTHobug4HUOMcVjAgjubStUDtLzSo2QDQAozGF8wdbeflaXuXkvUiX4H8ATe5H0LTyHQ%3D%3D\"}]}"},
             {"CF-RAY", "9d0671b70e43034d-MAD"}
           ],
           request_url: "https://api.warframe.market/v2/order",
           request: %HTTPoison.Request{
             method: :post,
             url: "https://api.warframe.market/v2/order",
             headers: [
               {"x-csrftoken",
                "##e56c26b281c5aad1543b370ab174e33b8137b1475dab87a84d91cffcb85e91ee1d9f065797b61855404458bffec0f6dd97678b65249d10bd36c1c2ed418c8b62"},
               {"Cookie",
                "JWT=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzaWQiOiJwdkNxdTdsUUFnaFpmNktjNnljSWRPeTVqdlJFN0d6TCIsImNzcmZfdG9rZW4iOiIzMDEzNDQ5ZjY0YmI3OWIzMGNkM2FlZTZiMDdjOTM4ZTNhNGMyNzNjIiwiZXhwIjoxNzc2Njk1MTkwLCJpYXQiOjE3NzE1MTExOTAsImlzcyI6Imp3dCIsImF1ZCI6Imp3dCIsImF1dGhfdHlwZSI6ImNvb2tpZSIsInNlY3VyZSI6dHJ1ZSwiand0X2lkZW50aXR5IjoiTnA5WEJSR0ZIeVJMN2dpZGJVa0lmcGRmbmY5d0FtMmYiLCJsb2dpbl91YSI6ImInaGFja25leS8xLjE3LjEnIiwibG9naW5faXAiOiJiJzc3LjIzMC4yMzcuMTgyJyJ9.fZ0G-g70WTHgpuRiyCV3ORY4406Y6DC-27Wh_lrMvY4"},
               {"Accept", "application/json"},
               {"Content-Type", "application/json"}
             ],
             body: "{\"type\":\"sell\",\"visible\":true,\"platinum\":20,\"rank\":0,\"quantity\":1,\"itemId\":\"1\"}",
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
      assert_received({:place_order, {:error, :invalid_item_id}})
    end

    test "returns correct 400 error for invalid email" do
      pid = self()

      request = %Request{
        metadata: %Metadata{send?: false, notify: [pid], operation: :login},
        args: %{
          name: "John",
          call:
            {nil,
             [
               "REQUEST_URL",
               [
                 {"Accept", "application/json"},
                 {"Content-Type", "application/json"}
               ]
             ]},
          retries: 0
        }
      }

      response =
        {:ok,
         %HTTPoison.Response{
           status_code: 400,
           body: "{\"apiVersion\":\"0.22.7\",\"data\":null,\"error\":{\"email\":[\"app.form.invalid\"]}}\n"
         }}

      response_fn = fn _response ->
        send(pid, :response_fn_ok)
        {:ok, nil}
      end

      assert HttpAsyncClient.handle_response(response, {response_fn, request}) == :ok
      refute_received(:response_fn_ok)
      assert_received({:login, {:error, :invalid_email}})
    end

    test "returns correct 400 error for incorrect password" do
      pid = self()

      request = %Request{
        metadata: %Metadata{send?: false, notify: [pid], operation: :login},
        args: %{
          name: "John",
          call:
            {nil,
             [
               "REQUEST_URL",
               [
                 {"Accept", "application/json"},
                 {"Content-Type", "application/json"}
               ]
             ]},
          retries: 0
        }
      }

      response =
        {:ok,
         %HTTPoison.Response{
           status_code: 400,
           body:
             "{\"apiVersion\":\"0.22.7\",\"data\":null,\"error\":{\"password\":[\"app.account.password_invalid\"]}}\n"
         }}

      response_fn = fn _response ->
        send(pid, :response_fn_ok)
        {:ok, nil}
      end

      assert HttpAsyncClient.handle_response(response, {response_fn, request}) == :ok
      refute_received(:response_fn_ok)
      assert_received({:login, {:error, :wrong_password}})
    end

    test "returns correct 400 error for incorrect email" do
      pid = self()

      request = %Request{
        metadata: %Metadata{send?: false, notify: [pid], operation: :login},
        args: %{
          name: "John",
          call:
            {nil,
             [
               "REQUEST_URL",
               [
                 {"Accept", "application/json"},
                 {"Content-Type", "application/json"}
               ]
             ]},
          retries: 0
        }
      }

      response =
        {:ok,
         %HTTPoison.Response{
           status_code: 400,
           body: "{\"apiVersion\":\"0.22.7\",\"data\":null,\"error\":{\"email\":[\"app.account.email_not_exist\"]}}\n"
         }}

      response_fn = fn _response ->
        send(pid, :response_fn_ok)
        {:ok, nil}
      end

      assert HttpAsyncClient.handle_response(response, {response_fn, request}) == :ok
      refute_received(:response_fn_ok)
      assert_received({:login, {:error, :wrong_email}})
    end

    test "returns correct 403 error for already placed order" do
      pid = self()

      request = %Request{
        metadata: %Metadata{send?: false, notify: [pid], operation: :place_order},
        args: %{
          name: "John",
          call:
            {nil,
             [
               "REQUEST_URL",
               [
                 {"Accept", "application/json"},
                 {"Content-Type", "application/json"}
               ]
             ]},
          retries: 0
        }
      }

      response =
        {:ok,
         %HTTPoison.Response{
           status_code: 403,
           body:
             "{\"apiVersion\":\"0.22.7\",\"data\":null,\"error\":{\"request\":[\"app.order.error.exceededOrderLimitSamePrice\"]}}\n",
           headers: [
             {"Date", "Thu, 19 Feb 2026 15:48:36 GMT"},
             {"Content-Type", "application/json"},
             {"Content-Length", "104"},
             {"Connection", "keep-alive"},
             {"Server", "cloudflare"},
             {"strict-transport-security", "max-age=2592000; includeSubDomains; preload"},
             {"cf-cache-status", "DYNAMIC"},
             {"Nel", "{\"report_to\":\"cf-nel\",\"success_fraction\":0.0,\"max_age\":604800}"},
             {"X-Content-Type-Options", "nosniff"},
             {"Report-To",
              "{\"group\":\"cf-nel\",\"max_age\":604800,\"endpoints\":[{\"url\":\"https://a.nel.cloudflare.com/report/v4?s=QD2%2BQgoOGSzUgR0JwKXL1fmqfejYeUKBfNXkMuvC%2BZuJV0jENgEIA0D6u57hhAUPHP5YX7g5ZDsbX%2Fcsuk6YYMcfL19gTcgECQkEvBS0CHM%3D\"}]}"},
             {"CF-RAY", "9d06e8d12b080390-MAD"}
           ],
           request_url: "https://api.warframe.market/v2/order",
           request: %HTTPoison.Request{
             method: :post,
             url: "https://api.warframe.market/v2/order",
             headers: [
               {"x-csrftoken",
                "##1a11d62f0703e528f0d4e69370cd5deffd8e1e3789daafa6ed2ee5655f8779be4fac37d52943777f0f34b3ae4863719d4cd14b8cf12f6f07a12855774ca55b54"},
               {"Cookie",
                "JWT=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzaWQiOiJnd010Q2xhVHhqdnA2Rm4wN3Y3THVlNXhHVHF6V3k5bSIsImNzcmZfdG9rZW4iOiI2MmExNWVhZTNlYmYwMzIwNjVhYjE3OWU4NDU0ODMzZTk1NTJmNjMzIiwiZXhwIjoxNzc2NzAwMDcyLCJpYXQiOjE3NzE1MTYwNzIsImlzcyI6Imp3dCIsImF1ZCI6Imp3dCIsImF1dGhfdHlwZSI6ImNvb2tpZSIsInNlY3VyZSI6dHJ1ZSwiand0X2lkZW50aXR5IjoiSUdTRHZEQXpUSllpNEpya0IyY295b0FMRjBDbm1Yd1kiLCJsb2dpbl91YSI6ImInaGFja25leS8xLjE3LjEnIiwibG9naW5faXAiOiJiJzc3LjIzMC4yMzcuMTgyJyJ9.ITwBzMLe-zq6O9T7OkhBBg5vPftDISKKX4rvKBCnrNc"},
               {"Accept", "application/json"},
               {"Content-Type", "application/json"}
             ],
             body:
               "{\"type\":\"sell\",\"visible\":true,\"platinum\":20,\"rank\":0,\"quantity\":1,\"itemId\":\"54e644ffe779897594fa68cd\"}",
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
      assert_received({:place_order, {:error, :order_already_placed}})
    end

    test "returns correct 404 error for non existing placed order" do
      pid = self()

      request = %Request{
        metadata: %Metadata{send?: false, notify: [pid], operation: :delete_order},
        args: %{
          name: "John",
          call:
            {nil,
             [
               "REQUEST_URL",
               [
                 {"Accept", "application/json"},
                 {"Content-Type", "application/json"}
               ]
             ]},
          retries: 0
        }
      }

      response =
        {:ok,
         %HTTPoison.Response{
           status_code: 404,
           body: "{\"apiVersion\":\"0.22.7\",\"data\":null,\"error\":{\"request\":[\"app.order.notFound\"]}}\n",
           headers: [
             {"Date", "Thu, 19 Feb 2026 15:30:41 GMT"},
             {"Content-Type", "application/json"},
             {"Content-Length", "79"},
             {"Connection", "keep-alive"},
             {"Server", "cloudflare"},
             {"strict-transport-security", "max-age=2592000; includeSubDomains; preload"},
             {"cf-cache-status", "DYNAMIC"},
             {"Nel", "{\"report_to\":\"cf-nel\",\"success_fraction\":0.0,\"max_age\":604800}"},
             {"X-Content-Type-Options", "nosniff"},
             {"Report-To",
              "{\"group\":\"cf-nel\",\"max_age\":604800,\"endpoints\":[{\"url\":\"https://a.nel.cloudflare.com/report/v4?s=bln%2F73z7WlvuAsClu8%2B9l%2FAzLd1VYk7iDkYFB%2BUbwRBOYScOhA7IxueEFNXrlra63TBReRlHvm7HVO5aCekWfuE1lP7Y1NMDtYGqYlrsFAMGIg%3D%3D\"}]}"},
             {"CF-RAY", "9d06ce8f48f40349-MAD"}
           ],
           request_url: "https://api.warframe.market/v2/order/626127cbc984ac033cd2bbd2",
           request: %HTTPoison.Request{
             method: :delete,
             url: "https://api.warframe.market/v2/order/626127cbc984ac033cd2bbd2",
             headers: [
               {"x-csrftoken",
                "##e1963e4720463812d8bebdbeb14e832206f0fa3a2a7e4897ff8515dad77c4f65c516e81ab4f0b0890c499f0ea6b8e1d98734590f0903c69a785f584d349fea96"},
               {"Cookie",
                "JWT=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzaWQiOiJiN04wUkNQczd0NENmNHdpOHltNjFyYkVNNEVzWkpMRyIsImNzcmZfdG9rZW4iOiIxMWU2ZTIzM2QyYjBmNzdlYjE0NmMzMmVkYjJmMmIwNjA2OWRmYzk1IiwiZXhwIjoxNzc2Njk4OTcxLCJpYXQiOjE3NzE1MTQ5NzEsImlzcyI6Imp3dCIsImF1ZCI6Imp3dCIsImF1dGhfdHlwZSI6ImNvb2tpZSIsInNlY3VyZSI6dHJ1ZSwiand0X2lkZW50aXR5IjoiWktTNDl3TmJsQzVLWDRtZnp6QlkwUHU5V1VaTTdkclQiLCJsb2dpbl91YSI6ImInaGFja25leS8xLjE3LjEnIiwibG9naW5faXAiOiJiJzc3LjIzMC4yMzcuMTgyJyJ9.YeVXUFpSbkMNnb9vqzGKti7XWlRqAAietpE30LywdIQ"},
               {"Accept", "application/json"},
               {"Content-Type", "application/json"}
             ],
             body: "",
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
      assert_received({:delete_order, {:error, :order_non_existent}})
    end

    test "returns correct 404 error for non existing item" do
      pid = self()

      request = %Request{
        metadata: %Metadata{send?: false, notify: [pid], operation: :get_item_orders},
        args: %{
          name: "John",
          call:
            {nil,
             [
               "REQUEST_URL",
               [
                 {"Accept", "application/json"},
                 {"Content-Type", "application/json"}
               ]
             ]},
          retries: 0
        }
      }

      response =
        {:ok,
         %HTTPoison.Response{
           status_code: 404,
           body: "{\"apiVersion\":\"0.22.7\",\"data\":null,\"error\":{\"request\":[\"app.item.notFound\"]}}\n"
         }}

      response_fn = fn _response ->
        send(pid, :response_fn_ok)
        {:ok, nil}
      end

      assert HttpAsyncClient.handle_response(response, {response_fn, request}) == :ok
      refute_received(:response_fn_ok)
      assert_received({:get_item_orders, {:error, :item_not_found}})
    end

    test "returns correct 429 error for making too many requests" do
      pid = self()

      request = %Request{
        metadata: %Metadata{send?: false, notify: [pid], operation: :delete_order},
        args: %{
          name: "John",
          call:
            {nil,
             [
               "REQUEST_URL",
               [
                 {"Accept", "application/json"},
                 {"Content-Type", "application/json"}
               ]
             ]},
          retries: 3
        }
      }

      response =
        {:ok,
         %HTTPoison.Response{
           status_code: 429,
           body: "{\"apiVersion\":\"0.22.7\",\"data\":null,\"error\":{\"request\":[\"app.order.notFound\"]}}\n",
           headers: [
             {"Date", "Thu, 19 Feb 2026 15:30:41 GMT"},
             {"Content-Type", "application/json"},
             {"Content-Length", "79"},
             {"Connection", "keep-alive"},
             {"Server", "cloudflare"},
             {"strict-transport-security", "max-age=2592000; includeSubDomains; preload"},
             {"cf-cache-status", "DYNAMIC"},
             {"Nel", "{\"report_to\":\"cf-nel\",\"success_fraction\":0.0,\"max_age\":604800}"},
             {"X-Content-Type-Options", "nosniff"},
             {"Report-To",
              "{\"group\":\"cf-nel\",\"max_age\":604800,\"endpoints\":[{\"url\":\"https://a.nel.cloudflare.com/report/v4?s=bln%2F73z7WlvuAsClu8%2B9l%2FAzLd1VYk7iDkYFB%2BUbwRBOYScOhA7IxueEFNXrlra63TBReRlHvm7HVO5aCekWfuE1lP7Y1NMDtYGqYlrsFAMGIg%3D%3D\"}]}"},
             {"CF-RAY", "9d06ce8f48f40349-MAD"}
           ],
           request_url: "https://api.warframe.market/v2/order/626127cbc984ac033cd2bbd2",
           request: %HTTPoison.Request{
             method: :delete,
             url: "https://api.warframe.market/v2/order/626127cbc984ac033cd2bbd2",
             headers: [
               {"x-csrftoken",
                "##e1963e4720463812d8bebdbeb14e832206f0fa3a2a7e4897ff8515dad77c4f65c516e81ab4f0b0890c499f0ea6b8e1d98734590f0903c69a785f584d349fea96"},
               {"Cookie",
                "JWT=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzaWQiOiJiN04wUkNQczd0NENmNHdpOHltNjFyYkVNNEVzWkpMRyIsImNzcmZfdG9rZW4iOiIxMWU2ZTIzM2QyYjBmNzdlYjE0NmMzMmVkYjJmMmIwNjA2OWRmYzk1IiwiZXhwIjoxNzc2Njk4OTcxLCJpYXQiOjE3NzE1MTQ5NzEsImlzcyI6Imp3dCIsImF1ZCI6Imp3dCIsImF1dGhfdHlwZSI6ImNvb2tpZSIsInNlY3VyZSI6dHJ1ZSwiand0X2lkZW50aXR5IjoiWktTNDl3TmJsQzVLWDRtZnp6QlkwUHU5V1VaTTdkclQiLCJsb2dpbl91YSI6ImInaGFja25leS8xLjE3LjEnIiwibG9naW5faXAiOiJiJzc3LjIzMC4yMzcuMTgyJyJ9.YeVXUFpSbkMNnb9vqzGKti7XWlRqAAietpE30LywdIQ"},
               {"Accept", "application/json"},
               {"Content-Type", "application/json"}
             ],
             body: "",
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
      assert_received({:delete_order, {:error, :slow_down}})
    end

    test "returns correct 500 server error" do
      pid = self()

      request = %Request{
        metadata: %Metadata{send?: false, notify: [pid], operation: :login},
        args: %{
          name: "John",
          call:
            {nil,
             [
               "REQUEST_URL",
               [
                 {"Accept", "application/json"},
                 {"Content-Type", "application/json"}
               ]
             ]},
          retries: 3
        }
      }

      response =
        {:ok, %HTTPoison.Response{status_code: 500}}

      response_fn = fn _response ->
        send(pid, :response_fn_ok)
        {:ok, nil}
      end

      assert HttpAsyncClient.handle_response(response, {response_fn, request}) == :ok
      refute_received(:response_fn_ok)
      assert_received({:login, {:error, :internal_server_error}})
    end

    test "returns correct 502 server error" do
      pid = self()

      request = %Request{
        metadata: %Metadata{send?: true, notify: [pid], operation: :login},
        args: %{
          name: "John",
          call:
            {nil,
             [
               "REQUEST_URL",
               [
                 {"Accept", "application/json"},
                 {"Content-Type", "application/json"}
               ]
             ]},
          retries: 3
        }
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

    test "returns correct 520 server error" do
      pid = self()

      request = %Request{
        metadata: %Metadata{send?: false, notify: [pid], operation: :login},
        args: %{
          name: "John",
          call:
            {nil,
             [
               "REQUEST_URL",
               [
                 {"Accept", "application/json"},
                 {"Content-Type", "application/json"}
               ]
             ]},
          retries: 3
        }
      }

      response =
        {:ok, %HTTPoison.Response{status_code: 520, body: "error code: 520"}}

      response_fn = fn _response ->
        send(pid, :response_fn_ok)
        {:ok, nil}
      end

      assert HttpAsyncClient.handle_response(response, {response_fn, request}) == :ok
      refute_received(:response_fn_ok)
      assert_received({:login, {:error, :unknown_server_error}})
    end

    test "returns correct error if we get an unknown error" do
      pid = self()

      request = %Request{
        metadata: %Metadata{send?: false, notify: [pid], operation: :login},
        args: %{
          name: "John",
          call:
            {nil,
             [
               "REQUEST_URL",
               [
                 {"Accept", "application/json"},
                 {"Content-Type", "application/json"}
               ]
             ]},
          retries: 0
        }
      }

      response =
        {:ok, %HTTPoison.Response{status_code: 1999, body: "error code: 1999"}}

      response_fn = fn _response ->
        send(pid, :response_fn_ok)
        {:ok, nil}
      end

      assert HttpAsyncClient.handle_response(response, {response_fn, request}) == :ok
      refute_received(:response_fn_ok)
      assert_received({:login, {:error, :unknown_error}})
    end

    test "returns error if it fails to make request" do
      pid = self()

      request = %Request{
        metadata: %Metadata{send?: false, notify: [pid], operation: :login},
        args: %{
          name: "John",
          call:
            {nil,
             [
               "REQUEST_URL",
               [
                 {"Accept", "application/json"},
                 {"Content-Type", "application/json"}
               ]
             ]},
          retries: 0
        }
      }

      response = {:error, %HTTPoison.Error{}}

      response_fn = fn _response ->
        send(pid, :response_fn_ok)
        {:ok, nil}
      end

      assert HttpAsyncClient.handle_response(response, {response_fn, request}) == :ok
      refute_received(:response_fn_ok)
      assert_received({:login, {:error, :request_failed}})
    end

    test "it retries request again if request failed with correct status_code" do
      defmodule RateLimiterMock do
        def make_request(_request_handler, {_original_response_fn, {_fn, original_request}}) do
          pid = self()

          assert original_request.args.call ==
                   {nil, ["REQUEST_URL", [{"Accept", "application/json"}, {"Content-Type", "application/json"}]]}

          assert original_request.args.retries == 1

          retry_response =
            {:ok,
             %HTTPoison.Response{
               status_code: 200,
               body: "{}",
               headers: [
                 {"Date", "Thu, 19 Feb 2026 14:27:18 GMT"},
                 {"Content-Type", "application/json"},
                 {"Content-Length", "86"},
                 {"Connection", "keep-alive"},
                 {"Server", "cloudflare"},
                 {"strict-transport-security", "max-age=2592000; includeSubDomains; preload"},
                 {"cf-cache-status", "DYNAMIC"},
                 {"Nel", "{\"report_to\":\"cf-nel\",\"success_fraction\":0.0,\"max_age\":604800}"},
                 {"X-Content-Type-Options", "nosniff"},
                 {"Report-To",
                  "{\"group\":\"cf-nel\",\"max_age\":604800,\"endpoints\":[{\"url\":\"https://a.nel.cloudflare.com/report/v4?s=jM1W3UQCzzzAONX%2B0tLzwGjfhgauYohMDQqfcW9VlGFTHobug4HUOMcVjAgjubStUDtLzSo2QDQAozGF8wdbeflaXuXkvUiX4H8ATe5H0LTyHQ%3D%3D\"}]}"},
                 {"CF-RAY", "9d0671b70e43034d-MAD"}
               ],
               request_url: "https://api.warframe.market/v2/order",
               request: %HTTPoison.Request{
                 method: :post,
                 url: "https://api.warframe.market/v2/order",
                 headers: [
                   {"x-csrftoken",
                    "##e56c26b281c5aad1543b370ab174e33b8137b1475dab87a84d91cffcb85e91ee1d9f065797b61855404458bffec0f6dd97678b65249d10bd36c1c2ed418c8b62"},
                   {"Cookie",
                    "JWT=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzaWQiOiJwdkNxdTdsUUFnaFpmNktjNnljSWRPeTVqdlJFN0d6TCIsImNzcmZfdG9rZW4iOiIzMDEzNDQ5ZjY0YmI3OWIzMGNkM2FlZTZiMDdjOTM4ZTNhNGMyNzNjIiwiZXhwIjoxNzc2Njk1MTkwLCJpYXQiOjE3NzE1MTExOTAsImlzcyI6Imp3dCIsImF1ZCI6Imp3dCIsImF1dGhfdHlwZSI6ImNvb2tpZSIsInNlY3VyZSI6dHJ1ZSwiand0X2lkZW50aXR5IjoiTnA5WEJSR0ZIeVJMN2dpZGJVa0lmcGRmbmY5d0FtMmYiLCJsb2dpbl91YSI6ImInaGFja25leS8xLjE3LjEnIiwibG9naW5faXAiOiJiJzc3LjIzMC4yMzcuMTgyJyJ9.fZ0G-g70WTHgpuRiyCV3ORY4406Y6DC-27Wh_lrMvY4"},
                   {"Accept", "application/json"},
                   {"Content-Type", "application/json"}
                 ],
                 body:
                   "{\"type\":\"sell\",\"visible\":true,\"platinum\":20,\"rank\":0,\"quantity\":1,\"itemId\":\"1\"}",
                 params: %{},
                 options: []
               }
             }}

          retry_response_fn = fn _response ->
            send(pid, :retry_response_fn_ok)
            {:ok, []}
          end

          HttpAsyncClient.handle_response(retry_response, {retry_response_fn, original_request}, %{rate_limiter: nil})
          :ok
        end
      end

      pid = self()

      request = %Request{
        metadata: %Metadata{send?: true, notify: [pid], operation: :get_item_orders},
        args: %{
          name: "John",
          call:
            {nil,
             [
               "REQUEST_URL",
               [
                 {"Accept", "application/json"},
                 {"Content-Type", "application/json"}
               ]
             ]},
          retries: 0
        }
      }

      response =
        {:ok,
         %HTTPoison.Response{
           status_code: 429,
           body:
             "{\"apiVersion\":\"0.22.7\",\"data\":null,\"error\":{\"inputs\":{\"itemId\":\"app.field.invalid\"}}}\n",
           headers: [
             {"Date", "Thu, 19 Feb 2026 14:27:18 GMT"},
             {"Content-Type", "application/json"},
             {"Content-Length", "86"},
             {"Connection", "keep-alive"},
             {"Server", "cloudflare"},
             {"strict-transport-security", "max-age=2592000; includeSubDomains; preload"},
             {"cf-cache-status", "DYNAMIC"},
             {"Nel", "{\"report_to\":\"cf-nel\",\"success_fraction\":0.0,\"max_age\":604800}"},
             {"X-Content-Type-Options", "nosniff"},
             {"Report-To",
              "{\"group\":\"cf-nel\",\"max_age\":604800,\"endpoints\":[{\"url\":\"https://a.nel.cloudflare.com/report/v4?s=jM1W3UQCzzzAONX%2B0tLzwGjfhgauYohMDQqfcW9VlGFTHobug4HUOMcVjAgjubStUDtLzSo2QDQAozGF8wdbeflaXuXkvUiX4H8ATe5H0LTyHQ%3D%3D\"}]}"},
             {"CF-RAY", "9d0671b70e43034d-MAD"}
           ],
           request_url: "https://api.warframe.market/v2/order",
           request: %HTTPoison.Request{
             method: :post,
             url: "https://api.warframe.market/v2/order",
             headers: [
               {"x-csrftoken",
                "##e56c26b281c5aad1543b370ab174e33b8137b1475dab87a84d91cffcb85e91ee1d9f065797b61855404458bffec0f6dd97678b65249d10bd36c1c2ed418c8b62"},
               {"Cookie",
                "JWT=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzaWQiOiJwdkNxdTdsUUFnaFpmNktjNnljSWRPeTVqdlJFN0d6TCIsImNzcmZfdG9rZW4iOiIzMDEzNDQ5ZjY0YmI3OWIzMGNkM2FlZTZiMDdjOTM4ZTNhNGMyNzNjIiwiZXhwIjoxNzc2Njk1MTkwLCJpYXQiOjE3NzE1MTExOTAsImlzcyI6Imp3dCIsImF1ZCI6Imp3dCIsImF1dGhfdHlwZSI6ImNvb2tpZSIsInNlY3VyZSI6dHJ1ZSwiand0X2lkZW50aXR5IjoiTnA5WEJSR0ZIeVJMN2dpZGJVa0lmcGRmbmY5d0FtMmYiLCJsb2dpbl91YSI6ImInaGFja25leS8xLjE3LjEnIiwibG9naW5faXAiOiJiJzc3LjIzMC4yMzcuMTgyJyJ9.fZ0G-g70WTHgpuRiyCV3ORY4406Y6DC-27Wh_lrMvY4"},
               {"Accept", "application/json"},
               {"Content-Type", "application/json"}
             ],
             body: "{\"type\":\"sell\",\"visible\":true,\"platinum\":20,\"rank\":0,\"quantity\":1,\"itemId\":\"1\"}",
             params: %{},
             options: []
           }
         }}

      response_fn = fn _response ->
        send(pid, :response_fn_ok)
        {:ok, nil}
      end

      assert HttpAsyncClient.handle_response(response, {response_fn, request}, %{rate_limiter: RateLimiterMock}) == :ok

      refute_received(:response_fn_ok)
      assert_received(:retry_response_fn_ok)
      assert_received({:get_item_orders, {:ok, []}})
    end
  end
end
