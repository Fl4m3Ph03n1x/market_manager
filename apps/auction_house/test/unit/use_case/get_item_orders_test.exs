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
                      "quantity": 1,
                      "creation_date": "2016-01-22T21:18:19.000+00:00",
                      "user": {
                          "reputation": 87,
                          "locale": "en",
                          "avatar": "user/avatar/56a293b3d3ffb60a43942be4.png?2b19ae420608cd7b816d931eb62db438",
                          "ingame_name": "JeyciKon",
                          "last_seen": "2025-06-17T02:34:40.464+00:00",
                          "slug": "jeycikon",
                          "crossplay": true,
                          "platform": "pc",
                          "id": "56a293b3d3ffb60a43942be4",
                          "region": "en",
                          "status": "offline"
                      },
                      "last_update": "2024-02-10T19:19:04.000+00:00",
                      "platinum": 22,
                      "order_type": "sell",
                      "id": "56a29c9bd3ffb60a4b3d32d3",
                      "mod_rank": 0,
                      "region": "en"
                  },
                  {
                      "visible": true,
                      "creation_date": "2016-07-21T09:00:36.000+00:00",
                      "quantity": 1,
                      "user": {
                          "reputation": 259,
                          "locale": "en",
                          "avatar": "user/avatar/55cbd976e77989320127aee2.png?5f4395ca16bc4bc35f7624dddc579cca",
                          "ingame_name": "nellone",
                          "last_seen": "2025-06-15T03:05:59.608+00:00",
                          "slug": "nellone",
                          "crossplay": true,
                          "platform": "pc",
                          "id": "55cbd976e77989320127aee2",
                          "region": "en",
                          "status": "ingame"
                      },
                      "last_update": "2025-04-13T00:59:28.000+00:00",
                      "platinum": 20,
                      "order_type": "sell",
                      "id": "57908f34d3ffb61fc81374a9",
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
                    user: %User{status: :offline, ingame_name: "JeyciKon", platform: :pc, crossplay: true},
                    platinum: 22,
                    order_type: :sell,
                    visible: true
                  },
                  %OrderInfo{
                    user: %User{
                      status: :ingame,
                      ingame_name: "nellone",
                      platform: :pc,
                      crossplay: true
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
