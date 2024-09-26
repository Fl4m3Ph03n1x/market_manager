defmodule AuctionHouse.Impl.UseCase.DeleteOrderTest do
  @moduledoc false

  use ExUnit.Case, async: true

  alias AuctionHouse.Impl.UseCase.DeleteOrder
  alias AuctionHouse.Impl.UseCase.Data.{Request, Response, Metadata}
  alias Jason
  alias Shared.Data.{Authorization, PlacedOrder}

  @url Application.compile_env!(:auction_house, :api_base_url)

  describe "start/2" do
    test "makes request" do
      auth = %Authorization{
        token:
          "##2263dcc167c732ca1b54566e0c1ffb66d8e13e2ed59d113967f7fb5e119fed0f813bf7b98c9777c2f5eafd0ab5f6fdc9ad5a3a44d8b585c07ebdf0af1be310b1",
        cookie:
          "JWT=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzaWQiOiJjR3ROWFUzaVR4bEg4UHh0M2pFN3NEN1kzQ3dwc0NLWCIsImNzcmZfdG9rZW4iOiIxOGQ4ZWMzODI0YzAzMjkzZjM1NjQ4OTA1OThhYjI5MDgyNWY0OTkyIiwiZXhwIjoxNzI3NzAxNDk4LCJpYXQiOjE3MjI1MTc0OTgsImlzcyI6Imp3dCIsImF1ZCI6Imp3dCIsImF1dGhfdHlwZSI6ImNvb2tpZSIsInNlY3VyZSI6dHJ1ZSwiand0X2lkZW50aXR5IjoiZXhqaGVEM1JhdVVLb0NOVUszdm11VW9kenBPT0t0bUIiLCJsb2dpbl91YSI6ImInaGFja25leS8xLjE3LjEnIiwibG9naW5faXAiOiJiJzE0Ny4xNjEuNjYuMzcnIn0.jWskOWec-x9pGtFHzB11LpUbynMMg-ARp2CgNx6VWJU"
      }

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

    test "returns deleted order", %{request: request} do
      response = %Response{
        request_args: request.args,
        metadata: request.metadata,
        headers: %{},
        body: """
        {{"payload": {"order_id": "66b9d5cf6b17410a639e2284"}}
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
