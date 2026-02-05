defmodule AuctionHouse.Impl.UseCase.GetUserOrdersTest do
  @moduledoc false

  use ExUnit.Case, async: true

  alias AuctionHouse.Impl.UseCase.GetUserOrders
  alias AuctionHouse.Impl.UseCase.Data.{Metadata, Request, Response}
  alias Jason

  @api_user_orders_url Application.compile_env!(:auction_house, :api_user_orders_url)

  describe "start/2" do
    test "makes request" do
      request = %Request{
        metadata: %Metadata{
          notify: [self()],
          operation: :get_user_orders,
          send?: false
        },
        args: %{
          username: "Fl4m3"
        }
      }

      deps =
        %{
          get: fn url, req, _next ->
            assert url == "#{@api_user_orders_url}/Fl4m3"

            assert req.metadata == %Metadata{
                     notify: [self()],
                     operation: :get_user_orders,
                     send?: true
                   }

            assert req.args.username == "Fl4m3"

            :ok
          end
        }

      assert GetUserOrders.start(request, deps) == :ok
    end
  end

  describe "finish/2" do
    setup do
      %{
        request: %Request{
          metadata: %Metadata{
            notify: [self()],
            operation: :get_user_orders,
            send?: true
          },
          args: %{
            username: "Fl4m3"
          }
        }
      }
    end

    test "returns parsed data", %{request: request} do
      response = %Response{
        request_args: request.args,
        metadata: request.metadata,
        headers: %{},
        body: """
        {
          "apiVersion": "0.22.7",
          "data": [
            {
              "id": "66a601d2adc83a241a38ede3",
              "type": "sell",
              "platinum": 2,
              "quantity": 21,
              "perTrade": 1,
              "rank": 0,
              "visible": true,
              "createdAt": "2025-12-04T22:13:20Z",
              "updatedAt": "2026-01-03T23:41:56Z",
              "itemId": "54e0c9eee7798903744178a7"
            },
            {
              "id": "66a601e1adc83a2414deabcd",
              "type": "sell",
              "platinum": 3,
              "quantity": 21,
              "perTrade": 1,
              "rank": 0,
              "visible": true,
              "createdAt": "2025-12-04T22:13:48Z",
              "updatedAt": "2026-01-03T23:41:55Z",
              "itemId": "5526aec0e779896af9418259"
            }
          ],
          "error": null
        }
        """
      }

      assert GetUserOrders.finish(response) ==
               {:ok,
                [
                  %Shared.Data.PlacedOrder{
                    item_id: "54e0c9eee7798903744178a7",
                    order_id: "66a601d2adc83a241a38ede3"
                  },
                  %Shared.Data.PlacedOrder{
                    item_id: "5526aec0e779896af9418259",
                    order_id: "66a601e1adc83a2414deabcd"
                  }
                ]}
    end

    test "returns empty if there are no orders", %{request: request} do
      response = %Response{
        request_args: request.args,
        metadata: request.metadata,
        headers: %{},
        body: """
        {
          "apiVersion": "0.22.7",
          "data": [],
          "error": null
        }
        """
      }

      assert GetUserOrders.finish(response) == {:ok, []}
    end

    test "returns error if it fails to decode", %{request: request} do
      response = %Response{
        request_args: request.args,
        metadata: request.metadata,
        headers: %{},
        body: ""
      }

      assert GetUserOrders.finish(response) ==
               {:error, %Jason.DecodeError{position: 0, token: nil, data: ""}}
    end
  end
end
