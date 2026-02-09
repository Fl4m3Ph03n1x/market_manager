defmodule AuctionHouseTest do
  @moduledoc false

  use ExUnit.Case, async: false

  alias AuctionHouse
  alias AuctionHouse.Runtime.AuctionSupervisor
  alias Bypass
  alias Shared.Data.{Authorization, Credentials, Order, OrderInfo, PlacedOrder}
  alias Shared.Data.OrderInfo.User
  alias Shared.Data.User, as: UserInfo

  @test_port 8082

  setup_all do
    bypass = Bypass.open(port: @test_port)
    _ = start_supervised(AuctionSupervisor)

    %{
      bypass: bypass
    }
  end

  describe "login/1" do
    test "receives {:ok, Authorization} when the login is successful", %{
      bypass: bypass
    } do
      # Arrange
      Bypass.expect(bypass, "GET", "/auth/signin", fn conn ->
        body = """
        <!DOCTYPE html>
        <html lang=en>
        <head>
        <meta charset="UTF-8">
        <meta name="csrf-token" content="##2263dcc167c732ca1b54566e0c1ffb66d8e13e2ed59d113967f7fb5e119fed0f813bf7b98c9777c2f5eafd0ab5f6fdc9ad5a3a44d8b585c07ebdf0af1be310b1">
        <link rel="canonical" href="https://warframe.market/auth/signin">
        <link rel="alternate" hreflang="en" href="https://warframe.market/auth/signin">
        <link rel="manifest" href="/manifest.json">
        <body>
        </body>
        </script>
        </html>
        """

        conn
        |> Plug.Conn.put_resp_header(
          "Set-Cookie",
          "JWT=old_cookie; Domain=.warframe.market; Expires=Tue, 21-Mar-2023 15:16:03 GMT; Secure; HttpOnly; Path=/; SameSite=Lax"
        )
        |> Plug.Conn.resp(200, body)
      end)

      Bypass.expect(bypass, "POST", "/v1/auth/signin", fn conn ->
        body =
          """
          {
            "payload": {
              "user": {
                "background": null,
                "crossplay": true,
                "ingame_name": "Fl4m3Ph03n1x",
                "platform": "pc",
                "region": "en",
                "avatar": "user/avatar/584d425cd3ffb630c3f9df42.png?0a8ad917dc66b85aa69520d70a31dafb",
                "linked_accounts": {
                  "steam_profile": true,
                  "patreon_profile": false,
                  "xbox_profile": false,
                  "discord_profile": false,
                  "github_profile": false
                },
                "slug": "fl4m3ph03n1x",
                "verification": true,
                "written_reviews": 0,
                "has_mail": true,
                "locale": "en",
                "unread_messages": 0,
                "check_code": "66BAPR88DLLZ",
                "banned": false,
                "role": "user",
                "id": "584d425cd3ffb630c3f9df42",
                "anonymous": false,
                "reputation": 339
              }
            }
          }
          """

        conn
        |> Plug.Conn.put_resp_header(
          "Set-Cookie",
          "JWT=new_cookie; Domain=.warframe.market; Expires=Tue, 21-Mar-2023 14:41:06 GMT; Secure; HttpOnly; Path=/; SameSite=Lax"
        )
        |> Plug.Conn.resp(200, body)
      end)

      credentials = %Credentials{
        email: "an_email",
        password: "password"
      }

      # Act
      assert AuctionHouse.login(credentials) == :ok

      assert_receive(
        {:login,
         {:ok,
          {%Authorization{
             token:
               "##2263dcc167c732ca1b54566e0c1ffb66d8e13e2ed59d113967f7fb5e119fed0f813bf7b98c9777c2f5eafd0ab5f6fdc9ad5a3a44d8b585c07ebdf0af1be310b1",
             cookie: "JWT=new_cookie"
           }, %UserInfo{patreon?: false, ingame_name: "Fl4m3Ph03n1x", slug: "fl4m3ph03n1x"}}}},
        3000
      )
    end
  end

  describe "place_oder/1" do
    test "receives {:ok, placed_order} if order was placed correctly", %{bypass: bypass} do
      # Arrange
      Bypass.expect(bypass, "POST", "/v2/order", fn conn ->
        response =
          """
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
              "itemId": "54a74454e779892d5e5155d5"
            },
            "error": null
          }
          """

        Plug.Conn.resp(conn, 200, response)
      end)

      order =
        Order.new(%{
          "order_type" => "sell",
          "item_id" => "54a74454e779892d5e5155d5",
          "platinum" => 15,
          "quantity" => 1,
          "mod_rank" => 0
        })

      auth = %Authorization{cookie: "cookie", token: "token"}
      user = %UserInfo{ingame_name: "Fl4m3", slug: "fl4m3", patreon?: false}

      :ok = AuctionHouse.update_login(auth, user)
      :ok = AuctionHouse.place_order(order)

      assert_receive(
        {:place_order,
         {:ok,
          %Shared.Data.PlacedOrder{
            item_id: "54a74454e779892d5e5155d5",
            order_id: "66b9c7aa6b17410a57974e4b"
          }}},
        3000
      )
    end
  end

  describe "delete_oder/1" do
    test "returns :ok if order was deleted correctly", %{bypass: bypass} do
      # Arrange
      Bypass.expect(bypass, "DELETE", "/v2/order/:id", fn conn ->
        response =
          """
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

        Plug.Conn.resp(conn, 200, Jason.encode!(response))
      end)

      placed_order =
        PlacedOrder.new(%{
          "order_id" => "5ee71a2604d55c0a5cbdc3c2",
          "item_id" => "57c73be094b4b0f159ab5e15"
        })

      auth = %Authorization{cookie: "cookie", token: "token"}
      user = %UserInfo{ingame_name: "Fl4m3", slug: "fl4m3", patreon?: false}

      :ok = AuctionHouse.update_login(auth, user)
      :ok = AuctionHouse.delete_order(placed_order)

      assert_receive(
        {:delete_order, {:ok, %PlacedOrder{item_id: "57c73be094b4b0f159ab5e15", order_id: "5ee71a2604d55c0a5cbdc3c2"}}},
        3000
      )
    end
  end

  describe "get_item_orders/1" do
    test "returns order_info if request for orders about item succeeded", %{
      bypass: bypass
    } do
      # Arrange
      Bypass.expect(bypass, "GET", "/v2/orders/item/:item_name", fn conn ->
        response =
          """
          {
            "apiVersion": "0.22.7",
            "data": [
              {
                "id": "598bd5b10f3139463a86b6af",
                "type": "sell",
                "platinum": 22,
                "quantity": 1,
                "perTrade": 1,
                "rank": 0,
                "visible": true,
                "createdAt": "2017-08-10T03:40:33Z",
                "updatedAt": "2026-01-29T02:51:53Z",
                "itemId": "54e644ffe779897594fa68d2",
                "user": {
                  "id": "5962ff05d3ffb64d46e3c47f",
                  "ingameName": "JeyciKon",
                  "slug": "jeycikon",
                  "reputation": 2,
                  "platform": "pc",
                  "crossplay": true,
                  "locale": "pt",
                  "status": "ingame",
                  "activity": {
                    "type": "UNKNOWN",
                    "details": "unknown"
                  },
                  "lastSeen": "2026-02-06T05:46:21Z"
                }
              },
              {
                "id": "59e9058dd3ffb666afc7942e",
                "type": "sell",
                "platinum": 20,
                "quantity": 4,
                "perTrade": 1,
                "rank": 0,
                "visible": true,
                "createdAt": "2017-10-19T20:05:33Z",
                "updatedAt": "2025-07-17T23:09:06Z",
                "itemId": "54e644ffe779897594fa68d2",
                "user": {
                  "id": "5663dab9b66f834eda2ede97",
                  "ingameName": "nellone",
                  "slug": "nellone",
                  "avatar": "user/avatar/5663dab9b66f834eda2ede97.png?63e97e14c2369b394cf660f9be64339f",
                  "reputation": 205,
                  "platform": "pc",
                  "crossplay": true,
                  "locale": "en",
                  "status": "ingame",
                  "activity": {
                    "type": "UNKNOWN",
                    "details": "unknown"
                  },
                  "lastSeen": "2026-02-06T06:15:52Z"
                }
              }
            ],
            "error": null
          }
          """

        Plug.Conn.resp(conn, 200, response)
      end)

      item_name = "Gleaming Blight"
      :ok = AuctionHouse.get_item_orders(item_name)

      assert_receive(
        {:get_item_orders,
         {:ok, ^item_name,
          [
            %OrderInfo{
              order_type: :sell,
              platinum: 22,
              user: %User{
                status: :ingame,
                ingame_name: "JeyciKon",
                platform: :pc,
                crossplay: true
              },
              visible: true
            },
            %OrderInfo{
              order_type: :sell,
              platinum: 20,
              user: %User{
                status: :ingame,
                ingame_name: "nellone",
                platform: :pc,
                crossplay: true
              },
              visible: true
            }
          ]}},
        3000
      )
    end
  end

  describe "get_user_orders/1" do
    test "returns user orders if request succeeds", %{bypass: bypass} do
      # Arrange
      Bypass.expect(bypass, "GET", "/v2/orders/user/:username", fn conn ->
        response =
          """
          {
            "apiVersion": "0.22.7",
            "data": [
              {
                "id": "66058313a9630600302d4889",
                "type": "sell",
                "platinum": 2,
                "quantity": 21,
                "perTrade": 1,
                "rank": 0,
                "visible": true,
                "createdAt": "2025-12-04T22:13:20Z",
                "updatedAt": "2026-01-03T23:41:56Z",
                "itemId": "55108594e77989728d5100c6"
              },
              {
                "id": "6605832ea96306003657a90d",
                "type": "sell",
                "platinum": 3,
                "quantity": 21,
                "perTrade": 1,
                "rank": 0,
                "visible": true,
                "createdAt": "2025-12-04T22:13:48Z",
                "updatedAt": "2026-01-03T23:41:55Z",
                "itemId": "54e644ffe779897594fa68d2"
              }
            ],
            "error": null
          }
          """

        Plug.Conn.resp(conn, 200, response)
      end)

      assert AuctionHouse.get_user_orders("fl4m3Ph03n1x") == :ok

      assert_receive(
        {:get_user_orders,
         {:ok,
          [
            %PlacedOrder{
              order_id: "66058313a9630600302d4889",
              item_id: "55108594e77989728d5100c6"
            },
            %PlacedOrder{
              order_id: "6605832ea96306003657a90d",
              item_id: "54e644ffe779897594fa68d2"
            }
          ]}},
        3000
      )
    end
  end

  describe "update_login/2" do
    test "updates server state correctly" do
      # Arrange
      auth = Authorization.new(%{"cookie" => "a_cookie", "token" => "a_token"})
      user = UserInfo.new(%{"ingame_name" => "Fl4m3", "slug" => "fl4m3", "patreon?" => false})

      assert :ok == AuctionHouse.update_login(auth, user)
    end
  end

  describe "get_saved_login/0" do
    test "returns server state correctly" do
      # Arrange
      auth = Authorization.new(%{"cookie" => "a_cookie", "token" => "a_token"})
      user = UserInfo.new(%{"ingame_name" => "Fl4m3", "slug" => "fl4m3", "patreon?" => false})

      assert :ok == AuctionHouse.update_login(auth, user)
      assert AuctionHouse.get_saved_login() == {:ok, {auth, user}}
    end
  end

  describe "logout/0" do
    test "deletes session correctly" do
      assert AuctionHouse.logout() == :ok
    end
  end
end
