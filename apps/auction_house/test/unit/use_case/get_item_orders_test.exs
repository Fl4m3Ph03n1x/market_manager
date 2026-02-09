defmodule AuctionHouse.Impl.UseCase.GetItemOrdersTest do
  @moduledoc false

  use ExUnit.Case, async: true

  alias AuctionHouse.Impl.UseCase.Data.{Metadata, Request, Response}
  alias AuctionHouse.Impl.UseCase.GetItemOrders
  alias Jason
  alias Shared.Data.OrderInfo
  alias Shared.Data.OrderInfo.User

  @search_url Application.compile_env!(:auction_house, :api_item_orders_url)

  describe "start/2" do
    test "makes request" do
      request = %Request{
        metadata: %Metadata{
          notify: [self()],
          operation: :get_item_orders,
          send?: false
        },
        args: %{
          item_name: "Despoil"
        }
      }

      deps =
        %{
          get: fn url, req, _next ->
            assert url == "#{@search_url}/despoil"

            assert req.metadata == %Metadata{
                     notify: [self()],
                     operation: :get_item_orders,
                     send?: true
                   }

            assert req.args.item_name == "Despoil"

            :ok
          end
        }

      assert GetItemOrders.start(request, deps) == :ok
    end
  end

  describe "finish/2" do
    setup do
      %{
        request: %Request{
          metadata: %Metadata{
            notify: [self()],
            operation: :get_item_orders,
            send?: true
          },
          args: %{
            item_name: "Despoil"
          }
        }
      }
    end

    test "returns parsed data", %{request: request} do
      response = %Response{
        metadata: request.metadata,
        request_args: request.args,
        headers: nil,
        body: """
        {
          "apiVersion": "0.22.7",
          "data": [
            {
              "id": "598bd5b10f3139463a86b6af",
              "type": "sell",
              "platinum": 22,
              "quantity": 1,
              "perTrade": 1,
              "rank": 0,
              "visible": true,
              "createdAt": "2017-08-10T03:40:33Z",
              "updatedAt": "2026-01-29T02:51:53Z",
              "itemId": "54e644ffe779897594fa68d2",
              "user": {
                "id": "5962ff05d3ffb64d46e3c47f",
                "ingameName": "JeyciKon",
                "slug": "jeycikon",
                "reputation": 2,
                "platform": "pc",
                "crossplay": true,
                "locale": "pt",
                "status": "offline",
                "activity": {
                  "type": "UNKNOWN",
                  "details": "unknown"
                },
                "lastSeen": "2026-02-06T05:46:21Z"
              }
            },
            {
              "id": "59e9058dd3ffb666afc7942e",
              "type": "sell",
              "platinum": 20,
              "quantity": 4,
              "perTrade": 1,
              "rank": 0,
              "visible": true,
              "createdAt": "2017-10-19T20:05:33Z",
              "updatedAt": "2025-07-17T23:09:06Z",
              "itemId": "54e644ffe779897594fa68d2",
              "user": {
                "id": "5663dab9b66f834eda2ede97",
                "ingameName": "nellone",
                "slug": "nellone",
                "avatar": "user/avatar/5663dab9b66f834eda2ede97.png?63e97e14c2369b394cf660f9be64339f",
                "reputation": 205,
                "platform": "pc",
                "crossplay": true,
                "locale": "en",
                "status": "ingame",
                "activity": {
                  "type": "UNKNOWN",
                  "details": "unknown"
                },
                "lastSeen": "2026-02-06T06:15:52Z"
              }
            }
          ],
          "error": null
        }
        """
      }

      assert GetItemOrders.finish(response) ==
               {:ok, "Despoil",
                [
                  %OrderInfo{
                    user: %User{
                      status: :offline,
                      ingame_name: "JeyciKon",
                      platform: :pc,
                      crossplay: true,
                      slug: "jeycikon"
                    },
                    platinum: 22,
                    order_type: :sell,
                    visible: true
                  },
                  %OrderInfo{
                    user: %User{
                      status: :ingame,
                      ingame_name: "nellone",
                      platform: :pc,
                      crossplay: true,
                      slug: "nellone"
                    },
                    platinum: 20,
                    order_type: :sell,
                    visible: true
                  }
                ]}
    end

    test "returns empty if there are no orders", %{request: request} do
      response = %Response{
        metadata: request.metadata,
        request_args: request.args,
        headers: %{},
        body: """
        {"data": []}
        """
      }

      assert GetItemOrders.finish(response) == {:ok, "Despoil", []}
    end

    test "returns error if it fails to decode", %{request: request} do
      response = %Response{
        metadata: request.metadata,
        request_args: request.args,
        headers: %{},
        body: ""
      }

      assert GetItemOrders.finish(response) ==
               {:error, "Despoil", %Jason.DecodeError{position: 0, token: nil, data: ""}}
    end
  end
end
