defmodule AuctionHouse.Impl.UseCase.PlaceOrderTest do
  @moduledoc false

  use ExUnit.Case, async: true

  alias AuctionHouse.Impl.UseCase.Data.{Metadata, Request, Response}
  alias AuctionHouse.Impl.UseCase.PlaceOrder
  alias Jason
  alias Shared.Data.{Authorization, PlacedOrder}

  @url Application.compile_env!(:auction_house, :api_order_url)

  describe "start/2" do
    test "makes request" do
      sell_order = %{
        type: "sell",
        visible: true,
        platinum: 20,
        rank: 0,
        quantity: 1,
        itemId: "54e644ffe779897594fa68cd"
      }

      auth = %Authorization{access_token: "a_token"}

      request = %Request{
        metadata: %Metadata{
          notify: [self()],
          operation: :place_order,
          send?: false
        },
        args: %{
          order: sell_order,
          authorization: auth
        }
      }

      deps =
        %{
          post: fn url, data, req, _next, auth ->
            assert url == @url
            assert data == Jason.encode!(sell_order)

            assert req.metadata == %Metadata{
                     notify: [self()],
                     operation: :place_order,
                     send?: true
                   }

            assert req.args.order == sell_order
            assert req.args.authorization == auth

            :ok
          end
        }

      assert PlaceOrder.start(request, deps) == :ok
    end
  end

  describe "finish/2" do
    setup do
      %{
        request: %Request{
          metadata: %Metadata{
            notify: [self()],
            operation: :place_order,
            send?: true
          },
          args: %{
            order: %{
              type: "sell",
              visible: true,
              platinum: 20,
              rank: 0,
              quantity: 1,
              itemId: "54e644ffe779897594fa68cd"
            },
            authorization: %Authorization{access_token: "a_token"}
          }
        }
      }
    end

    test "returns parsed data", %{request: req} do
      response = %Response{
        metadata: req.metadata,
        request_args: req.args,
        headers: %{},
        body: """
        {
          "apiVersion": "0.22.7",
          "data": {
            "id": "66b9c7aa6b17410a57974e4b",
            "type": "sell",
            "platinum": 11,
            "quantity": 1,
            "perTrade": 1,
            "rank": 0,
            "visible": true,
            "createdAt": "2026-02-05T15:17:18Z",
            "updatedAt": "2026-02-05T15:17:18Z",
            "itemId": "54e644ffe779897594fa68cd"
          },
          "error": null
        }
        """
      }

      assert PlaceOrder.finish(response) ==
               {:ok,
                %PlacedOrder{
                  item_id: "54e644ffe779897594fa68cd",
                  order_id: "66b9c7aa6b17410a57974e4b"
                }}
    end

    test "returns error if there is no order", %{request: req} do
      response = %Response{
        metadata: req.metadata,
        request_args: req.args,
        headers: %{},
        body: """
              {"data": {}}
        """
      }

      assert PlaceOrder.finish(response) == {:error, {:missing_order, %{"data" => %{}}}}
    end

    test "returns error if it fails to decode", %{request: req} do
      response = %Response{
        metadata: req.metadata,
        request_args: req.args,
        headers: %{},
        body: ""
      }

      assert PlaceOrder.finish(response) ==
               {:error, %Jason.DecodeError{position: 0, token: nil, data: ""}}
    end
  end
end
