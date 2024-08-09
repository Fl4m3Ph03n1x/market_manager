defmodule AuctionHouse.Impl.PlaceOrderTest do
  @moduledoc false

  use ExUnit.Case, async: true

  alias AuctionHouse.Impl.PlaceOrder
  alias Jason
  alias Shared.Data.{Authorization, Order}

  @url Application.compile_env!(:auction_house, :api_base_url)

  describe "run/2" do
    test "makes request" do
      pid = self()

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

      metadata = %{
        from: [pid],
        operation: :place_order,
        send?: false,
        order: order,
        authorization: auth
      }

      deps =
        %{
          post: fn url, data, auth, meta, _next ->
            assert url == @url
            assert data == Jason.encode!(order)

            assert meta == %{
                     from: [pid],
                     operation: :place_order,
                     send?: true,
                     order: order,
                     authorization: auth
                   }

            :ok
          end
        }

      assert PlaceOrder.run(metadata, deps) == :ok
    end
  end

  describe "parse_placed_order/2" do
    setup do
      %{
        from: [self()],
        operation: :place_order,
        send?: true,
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
    end

    test "returns parsed data", metadata do
      body = """
      """

      assert PlaceOrder.parse_placed_order({body, []}, metadata) ==
               {:ok, nil}
    end

    test "returns empty if there are no orders", metadata do
      body = """
      """

      assert PlaceOrder.parse_placed_order({body, []}, metadata) == {:ok, []}
    end

    test "returns error if it fails to decode", metadata do
      body = ""

      assert PlaceOrder.parse_placed_order({body, []}, metadata) ==
               {:error, %Jason.DecodeError{position: 0, token: nil, data: ""}}
    end
  end
end
