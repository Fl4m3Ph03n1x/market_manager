defmodule AuctionHouse.Impl.UseCase.GetUserOrdersTest do
  @moduledoc false

  use ExUnit.Case, async: true

  alias AuctionHouse.Impl.UseCase.GetUserOrders
  alias AuctionHouse.Impl.UseCase.Data.{Metadata, Request, Response}
  alias Jason

  @api_profile_url Application.compile_env!(:auction_house, :api_profile_url)

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
            assert url == "#{@api_profile_url}/Fl4m3/orders"

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
        "payload": {
        "sell_orders": [
        {
        "order_type": "sell",
        "region": "en",
        "mod_rank": 0,
        "id": "66a601d2adc83a241a38ede3",
        "platform": "pc",
        "item": {
          "id": "54e0c9eee7798903744178a7",
          "sub_icon": null,
          "url_name": "counter_pulse",
          "tags": [
            "mod",
            "rare",
            "warframe",
            "mag"
          ],
          "thumb": "items/images/en/thumbs/counter_pulse.7f88af7ba65853e9e371265203a77526.128x128.png",
          "icon": "items/images/en/counter_pulse.7f88af7ba65853e9e371265203a77526.png",
          "mod_max_rank": 3,
          "icon_format": "port",
          "en": {
            "item_name": "Counter Pulse"
          }
        },
        "creation_date": "2024-07-28T08:31:14.099+00:00",
        "last_update": "2024-07-30T16:32:20.594+00:00",
        "quantity": 1,
        "visible": true,
        "platinum": 17
        },
        {
        "order_type": "sell",
        "region": "en",
        "mod_rank": 0,
        "id": "66a601e1adc83a2414deabcd",
        "platform": "pc",
        "item": {
          "id": "5526aec0e779896af9418259",
          "sub_icon": null,
          "url_name": "fracturing_crush",
          "tags": [
            "mod",
            "rare",
            "warframe",
            "mag"
          ],
          "thumb": "items/images/en/thumbs/fracturing_crush.c5cfd74639913a1d6e95631afdbcb475.128x128.png",
          "icon": "items/images/en/fracturing_crush.c5cfd74639913a1d6e95631afdbcb475.png",
          "mod_max_rank": 3,
          "icon_format": "port",
          "en": {
            "item_name": "Fracturing Crush"
          }
        },
        "creation_date": "2024-07-28T08:31:29.275+00:00",
        "last_update": "2024-08-04T16:55:14.261+00:00",
        "quantity": 1,
        "visible": true,
        "platinum": 14
        }
        ],
        "buy_orders": []
        }
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
        "payload": {
        "sell_orders": [],
        "buy_orders": []
        }
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
