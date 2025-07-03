defmodule AuctionHouse.Impl.UseCase.PlaceOrderTest do
  @moduledoc false

  use ExUnit.Case, async: true

  alias AuctionHouse.Impl.UseCase.Data.{Metadata, Request, Response}
  alias AuctionHouse.Impl.UseCase.PlaceOrder
  alias Jason
  alias Shared.Data.{Authorization, Order, PlacedOrder}

  @url Application.compile_env!(:auction_house, :api_base_url)

  describe "start/2" do
    test "makes request" do
      order =
        Order.new(%{
          "item_id" => "54e644ffe779897594fa68cd",
          "mod_rank" => 0,
          "order_type" => "sell",
          "platinum" => 20,
          "quantity" => 1
        })

      auth = %Authorization{
        token:
          "##2263dcc167c732ca1b54566e0c1ffb66d8e13e2ed59d113967f7fb5e119fed0f813bf7b98c9777c2f5eafd0ab5f6fdc9ad5a3a44d8b585c07ebdf0af1be310b1",
        cookie:
          "JWT=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzaWQiOiJjR3ROWFUzaVR4bEg4UHh0M2pFN3NEN1kzQ3dwc0NLWCIsImNzcmZfdG9rZW4iOiIxOGQ4ZWMzODI0YzAzMjkzZjM1NjQ4OTA1OThhYjI5MDgyNWY0OTkyIiwiZXhwIjoxNzI3NzAxNDk4LCJpYXQiOjE3MjI1MTc0OTgsImlzcyI6Imp3dCIsImF1ZCI6Imp3dCIsImF1dGhfdHlwZSI6ImNvb2tpZSIsInNlY3VyZSI6dHJ1ZSwiand0X2lkZW50aXR5IjoiZXhqaGVEM1JhdVVLb0NOVUszdm11VW9kenBPT0t0bUIiLCJsb2dpbl91YSI6ImInaGFja25leS8xLjE3LjEnIiwibG9naW5faXAiOiJiJzE0Ny4xNjEuNjYuMzcnIn0.jWskOWec-x9pGtFHzB11LpUbynMMg-ARp2CgNx6VWJU"
      }

      request = %Request{
        metadata: %Metadata{
          notify: [self()],
          operation: :place_order,
          send?: false
        },
        args: %{
          order: order,
          authorization: auth
        }
      }

      deps =
        %{
          post: fn url, data, req, _next, auth ->
            assert url == @url
            assert data == Jason.encode!(order)

            assert req.metadata == %Metadata{
                     notify: [self()],
                     operation: :place_order,
                     send?: true
                   }

            assert req.args.order == order
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
            order:
              Order.new(%{
                "item_id" => "54e644ffe779897594fa68cd",
                "mod_rank" => 0,
                "order_type" => "sell",
                "platinum" => 20,
                "quantity" => 1
              }),
            authorization: %Authorization{
              token:
                "##2263dcc167c732ca1b54566e0c1ffb66d8e13e2ed59d113967f7fb5e119fed0f813bf7b98c9777c2f5eafd0ab5f6fdc9ad5a3a44d8b585c07ebdf0af1be310b1",
              cookie:
                "JWT=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzaWQiOiJjR3ROWFUzaVR4bEg4UHh0M2pFN3NEN1kzQ3dwc0NLWCIsImNzcmZfdG9rZW4iOiIxOGQ4ZWMzODI0YzAzMjkzZjM1NjQ4OTA1OThhYjI5MDgyNWY0OTkyIiwiZXhwIjoxNzI3NzAxNDk4LCJpYXQiOjE3MjI1MTc0OTgsImlzcyI6Imp3dCIsImF1ZCI6Imp3dCIsImF1dGhfdHlwZSI6ImNvb2tpZSIsInNlY3VyZSI6dHJ1ZSwiand0X2lkZW50aXR5IjoiZXhqaGVEM1JhdVVLb0NOVUszdm11VW9kenBPT0t0bUIiLCJsb2dpbl91YSI6ImInaGFja25leS8xLjE3LjEnIiwibG9naW5faXAiOiJiJzE0Ny4xNjEuNjYuMzcnIn0.jWskOWec-x9pGtFHzB11LpUbynMMg-ARp2CgNx6VWJU"
            }
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
        "payload": {
          "order": {
              "visible": true,
              "order_type": "sell",
              "quantity": 1,
              "mod_rank": 0,
              "region": "en",
              "last_update": "2024-08-12T08:28:26.898+00:00",
              "platform": "pc",
              "platinum": 20,
              "item": {
                  "sub_icon": null,
                  "mod_max_rank": 3,
                  "icon_format": "port",
                  "thumb": "items/images/en/thumbs/despoil.2633a2c7793d85b21d22cb4c4a0b70cf.128x128.png",
                  "url_name": "despoil",
                  "icon": "items/images/en/despoil.2633a2c7793d85b21d22cb4c4a0b70cf.png",
                  "id": "54e644ffe779897594fa68cd",
                  "tags": [
                      "mod",
                      "rare",
                      "warframe",
                      "nekros"
                  ],
                  "en": {
                      "item_name": "Despoil"
                  }
              },
              "creation_date": "2024-08-12T08:28:26.898+00:00",
              "id": "66b9c7aa6b17410a57974e4b"
          }
        }
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

    test "returns error if there is no order id", %{request: req} do
      response = %Response{
        metadata: req.metadata,
        request_args: req.args,
        headers: %{},
        body: """
        {"payload": {"order": {}}}
        """
      }

      assert PlaceOrder.finish(response) ==
               {:error, {:missing_id, %{"payload" => %{"order" => %{}}}}}
    end

    test "returns error if there is no order", %{request: req} do
      response = %Response{
        metadata: req.metadata,
        request_args: req.args,
        headers: %{},
        body: """
              {"payload": {}}
        """
      }

      assert PlaceOrder.finish(response) == {:error, {:missing_order, %{"payload" => %{}}}}
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
