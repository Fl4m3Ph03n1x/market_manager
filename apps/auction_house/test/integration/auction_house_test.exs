defmodule AuctionHouseTest do
  @moduledoc false

  use ExUnit.Case

  alias AuctionHouse
  alias AuctionHouse.Data.{Order, OrderInfo, LoginInfo}
  alias AuctionHouse.Data.OrderInfo.User
  alias AuctionHouse.Runtime.Server
  alias Bypass

  @test_port 8082

  setup do
    {:ok, pid} = start_supervised(Server)
    bypass = Bypass.open(port: @test_port)
    %{bypass: bypass, server: pid}
  end

  describe "place_oder/1" do
    test "returns {:ok, order_id} if order was placed correctly", %{
      bypass: bypass,
      server: server
    } do
      # Arrange
      Bypass.expect(bypass, "POST", "/v1/profile/orders", fn conn ->
        response = %{
          "payload" => %{
            "order" => %{
              "creation_date" => "2020-06-15T06:50:14.248+00:00",
              "id" => "5ee71a2604d55c0a5cbdc3c2",
              "item" => %{
                "de" => %{"item_name" => "Toxic Sequence"},
                "en" => %{"item_name" => "Toxic Sequence"},
                "fr" => %{"item_name" => "Toxic Sequence"},
                "icon" => "icons/en/Toxic_Sequence.bab0370da343ca58b4b92fca65b1da6a.png",
                "id" => "54a74454e779892d5e5155e3",
                "ko" => %{"item_name" => "톡식 시퀀스"},
                "mod_max_rank" => 3,
                "pt" => %{"item_name" => "Toxic Sequence"},
                "ru" => %{
                  "item_name" => "Токсичная последовательность"
                },
                "sub_icon" => nil,
                "sv" => %{"item_name" => "Toxic Sequence"},
                "tags" => ["mod", "weapons", "rare"],
                "thumb" =>
                  "icons/en/thumbs/Toxic_Sequence.bab0370da343ca58b4b92fca65b1da6a.128x128.png",
                "url_name" => "toxic_sequence",
                "zh" => %{"item_name" => "Toxic Sequence"}
              },
              "last_update" => "2020-06-15T06:50:14.248+00:00",
              "mod_rank" => 0,
              "order_type" => "sell",
              "platform" => "pc",
              "platinum" => 15.0,
              "quantity" => 1,
              "region" => "en",
              "visible" => true
            }
          }
        }

        Plug.Conn.resp(conn, 200, Jason.encode!(response))
      end)

      order = %Order{
        order_type: "sell",
        item_id: "54a74454e779892d5e5155d5",
        platinum: 15,
        quantity: 1,
        mod_rank: 0
      }

      login_info = %LoginInfo{cookie: "cookie", token: "token", patreon?: false}
      :sys.replace_state(server, fn state -> Map.put(state, :authorization, login_info) end)

      # Act
      actual = AuctionHouse.place_order(order)
      expected = {:ok, "5ee71a2604d55c0a5cbdc3c2"}

      # Assert
      assert actual == expected
    end
  end

  describe "delete_oder/1" do
    test "returns {:ok, order_id} if order was deleted correctly", %{
      bypass: bypass,
      server: server
    } do
      # Arrange
      Bypass.expect(bypass, "DELETE", "/v1/profile/orders/:id", fn conn ->
        response = %{"payload" => %{"order_id" => "5ee71a2604d55c0a5cbdc3c2"}}
        Plug.Conn.resp(conn, 200, Jason.encode!(response))
      end)

      order_id = "5ee71a2604d55c0a5cbdc3c2"
      login_info = %LoginInfo{cookie: "cookie", token: "token", patreon?: false}
      :sys.replace_state(server, fn state -> Map.put(state, :authorization, login_info) end)

      # Act
      actual = AuctionHouse.delete_order(order_id)
      expected = {:ok, "5ee71a2604d55c0a5cbdc3c2"}

      # Assert
      assert actual == expected
    end
  end

  describe "get_all_orders/2" do
    test "returns {:ok, [order_info]} if request for orders about item succeeded", %{
      bypass: bypass
    } do
      # Arrange
      Bypass.expect(bypass, "GET", "/v1/items/:item_name/orders", fn conn ->
        response = %{
          "payload" => %{
            "orders" => [
              %{
                "creation_date" => "2019-01-05T20:52:40.000+00:00",
                "id" => "5c311918716c98021463eb32",
                "last_update" => "2019-04-01T09:39:58.000+00:00",
                "order_type" => "sell",
                "platform" => "pc",
                "platinum" => 45,
                "quantity" => 1,
                "region" => "en",
                "user" => %{
                  "avatar" => nil,
                  "id" => "598c96d60f313948524a2b66",
                  "ingame_name" => "Elect4k",
                  "last_seen" => "2020-07-20T18:20:28.422+00:00",
                  "region" => "en",
                  "reputation" => 2,
                  "reputation_bonus" => 0,
                  "status" => "ingame"
                },
                "visible" => true
              },
              %{
                "creation_date" => "2019-02-08T22:11:22.000+00:00",
                "id" => "5c5dfe8a83d1620563a75a7d",
                "last_update" => "2020-07-02T14:53:06.000+00:00",
                "order_type" => "sell",
                "platform" => "pc",
                "platinum" => 30,
                "quantity" => 2,
                "region" => "en",
                "user" => %{
                  "avatar" =>
                    "user/avatar/55d77904e779893a9827aee2.png?9b0eed7b4885f4ec4275240b3035aa55",
                  "id" => "55d77904e779893a9827aee2",
                  "ingame_name" => "porottaja",
                  "last_seen" => "2020-07-18T13:58:49.665+00:00",
                  "region" => "en",
                  "reputation" => 28,
                  "reputation_bonus" => 0,
                  "status" => "ingame"
                },
                "visible" => true
              }
            ]
          }
        }

        Plug.Conn.resp(conn, 200, Jason.encode!(response))
      end)

      item_name = "Gleaming Blight"

      # Act
      actual = AuctionHouse.get_all_orders(item_name)

      expected =
        {:ok,
         [
           %OrderInfo{
             order_type: "sell",
             platform: "pc",
             platinum: 45,
             user: %User{
               status: "ingame",
               ingame_name: "Elect4k"
             },
             visible: true
           },
           %OrderInfo{
             order_type: "sell",
             platform: "pc",
             platinum: 30,
             user: %User{
               status: "ingame",
               ingame_name: "porottaja"
             },
             visible: true
           }
         ]}

      # Assert
      assert actual == expected
    end
  end

  # describe "update_credentials/1" do
  #   test "returns {:ok, credentials} when the update is successfull" do
  #     # Arrange
  #     credentials = %{
  #       "cookie" => "a_cookie",
  #       "token" => "a_token"
  #     }

  #     # Act
  #     actual = AuctionHouse.update_credentials(credentials)
  #     expected = {:ok, credentials}

  #     # Assert
  #     assert actual == expected
  #   end
  # end
end
