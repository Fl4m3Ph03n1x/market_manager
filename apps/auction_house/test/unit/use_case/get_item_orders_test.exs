defmodule AuctionHouse.Impl.UseCase.GetItemOrdersTest do
  @moduledoc false

  use ExUnit.Case, async: true

  alias AuctionHouse.Impl.UseCase.Data.{Metadata, Request, Response}
  alias AuctionHouse.Impl.UseCase.GetItemOrders
  alias Jason
  alias Shared.Data.OrderInfo
  alias Shared.Data.OrderInfo.User

  @search_url Application.compile_env!(:auction_house, :api_search_url)

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
            assert url == "#{@search_url}/despoil/orders"

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
        "payload": {
          "orders": [
              {
                  "visible": true,
                  "creation_date": "2016-07-21T09:00:36.000+00:00",
                  "quantity": 1,
                  "user": {
                      "reputation": 193,
                      "locale": "en",
                      "avatar": "user/avatar/55cbd976e77989320127aee2.png?5f4395ca16bc4bc35f7624dddc579cca",
                      "ingame_name": "nellone",
                      "last_seen": "2024-08-08T01:14:56.017+00:00",
                      "id": "55cbd976e77989320127aee2",
                      "region": "en",
                      "status": "offline"
                  },
                  "last_update": "2024-01-15T14:07:15.000+00:00",
                  "platinum": 20,
                  "order_type": "sell",
                  "platform": "pc",
                  "id": "57908f34d3ffb61fc81374a9",
                  "mod_rank": 0,
                  "region": "en"
              },
              {
                  "visible": true,
                  "quantity": 4,
                  "creation_date": "2017-10-19T20:03:12.000+00:00",
                  "user": {
                      "reputation": 138,
                      "locale": "en",
                      "avatar": "user/avatar/5663dab9b66f834eda2ede97.png?63e97e14c2369b394cf660f9be64339f",
                      "ingame_name": "SasoDuck",
                      "last_seen": "2024-08-09T08:44:41.042+00:00",
                      "id": "5663dab9b66f834eda2ede97",
                      "region": "en",
                      "status": "ingame"
                  },
                  "last_update": "2024-06-04T21:18:21.000+00:00",
                  "platinum": 25,
                  "order_type": "sell",
                  "platform": "pc",
                  "id": "59e905000f31396a96820488",
                  "mod_rank": 0,
                  "region": "en"
              }
          ]
        }
        }
        """
      }

      assert GetItemOrders.finish(response) ==
               {:ok, "Despoil",
                [
                  %OrderInfo{
                    user: %User{status: "offline", ingame_name: "nellone"},
                    platinum: 20,
                    platform: "pc",
                    order_type: "sell",
                    visible: true
                  },
                  %OrderInfo{
                    user: %Shared.Data.OrderInfo.User{status: "ingame", ingame_name: "SasoDuck"},
                    platinum: 25,
                    platform: "pc",
                    order_type: "sell",
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
        {"payload": {"orders": []}}
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
