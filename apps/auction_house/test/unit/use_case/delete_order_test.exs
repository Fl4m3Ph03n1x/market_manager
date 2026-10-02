defmodule AuctionHouse.Impl.UseCase.DeleteOrderTest do
  @moduledoc false

  use ExUnit.Case, async: true

  alias AuctionHouse.Impl.UseCase.Data.{Metadata, Request, Response}
  alias AuctionHouse.Impl.UseCase.DeleteOrder
  alias Jason
  alias Shared.Data.{Authorization, PlacedOrder}

  @url Application.compile_env!(:auction_house, :api_order_url)

  describe "start/2" do
    test "makes request" do
      auth = %Authorization{access_token: "a_token"}

      placed_order =
        %PlacedOrder{
          item_id: "54e644ffe779897594fa68cd",
          order_id: "66b9d5cf6b17410a639e2284"
        }

      request = %Request{
        metadata: %Metadata{
          notify: [self()],
          operation: :delete_order,
          send?: false
        },
        args: %{
          authorization: auth,
          placed_order: placed_order
        }
      }

      deps = %{
        delete: fn url, req, _next, auth ->
          assert url == "#{@url}/66b9d5cf6b17410a639e2284"
          assert req.args.authorization == auth
          assert req.args.placed_order == placed_order

          assert req.metadata == %Metadata{
                   notify: [self()],
                   operation: :delete_order,
                   send?: true
                 }

          :ok
        end
      }

      assert DeleteOrder.start(request, deps) == :ok
    end
  end

  describe "finish/2" do
    setup do
      %{
        request: %Request{
          metadata: %Metadata{
            notify: [self()],
            operation: :delete_order,
            send?: true
          },
          args: %{
            placed_order: %PlacedOrder{
              item_id: "54e644ffe779897594fa68cd",
              order_id: "66b9d5cf6b17410a639e2284"
            },
            authorization: %Authorization{access_token: "a_token"}
          }
        }
      }
    end

    test "returns deleted order", %{request: request} do
      response = %Response{
        request_args: request.args,
        metadata: request.metadata,
        headers: %{},
        body: """
        {
          "apiVersion": "0.22.7",
          "data": {
            "id": "693207daaffbfaaa4e2474e5",
            "type": "sell",
            "platinum": 2,
            "quantity": 21,
            "perTrade": 1,
            "rank": 0,
            "visible": false,
            "createdAt": "2025-12-04T22:14:50Z",
            "updatedAt": "2026-01-03T23:41:58Z",
            "itemId": "675c5ee47b18977f6e6453f6"
          },
          "error": null
        }
        """
      }

      assert DeleteOrder.finish(response) ==
               {:ok,
                %PlacedOrder{
                  item_id: "54e644ffe779897594fa68cd",
                  order_id: "66b9d5cf6b17410a639e2284"
                }}
    end
  end
end
