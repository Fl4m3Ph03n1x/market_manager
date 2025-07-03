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
  end
end
