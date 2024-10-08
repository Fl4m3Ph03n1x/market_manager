defmodule AuctionHouseTest do
  @moduledoc false

  use ExUnit.Case, async: false

  alias AuctionHouse
  alias Bypass
  alias Shared.Data.{Authorization, Credentials, Order, OrderInfo, PlacedOrder}
  alias Shared.Data.OrderInfo.User
  alias Shared.Data.User, as: UserInfo

  @test_port 8082

  setup_all do
    bypass = Bypass.open(port: @test_port)
    {:ok, _pid} = AuctionHouse.Runtime.AuctionSupervisor.start_link()

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
          "{\"payload\": {\"user\": {\"has_mail\": true, \"written_reviews\": 0, \"region\": \"en\", \"banned\": false, \"anonymous\": false, \"role\": \"user\", \"reputation\": 84, \"ingame_name\": \"Fl4m3Ph03n1x\", \"platform\": \"pc\", \"unread_messages\": 0, \"background\": null, \"check_code\": \"66BAPR88DLLZ\", \"avatar\": \"user/avatar/584d425cd3ffb630c3f9df42.png?0a8ad917dc66b85aa69520d70a31dafb\", \"verification\": true, \"linked_accounts\": {\"steam_profile\": true, \"patreon_profile\": false, \"xbox_profile\": false, \"discord_profile\": false, \"github_profile\": false}, \"id\": \"584d425cd3ffb630c3f9df42\", \"locale\": \"en\"}}}"

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
          {%Shared.Data.Authorization{
             token:
               "##2263dcc167c732ca1b54566e0c1ffb66d8e13e2ed59d113967f7fb5e119fed0f813bf7b98c9777c2f5eafd0ab5f6fdc9ad5a3a44d8b585c07ebdf0af1be310b1",
             cookie: "JWT=new_cookie"
           }, %Shared.Data.User{patreon?: false, ingame_name: "Fl4m3Ph03n1x"}}}},
        3000
      )
    end
  end

  describe "place_oder/1" do
    test "receives {:ok, placed_order} if order was placed correctly", %{bypass: bypass} do
      # Arrange
      Bypass.expect(bypass, "POST", "/v1/profile/orders", fn conn ->
        response =
          %{
            "payload" => %{
              "order" => %{
                "visible" => true,
                "order_type" => "sell",
                "quantity" => 1,
                "mod_rank" => 0,
                "region" => "en",
                "last_update" => "2024-08-12T08:28:26.898+00:00",
                "platform" => "pc",
                "platinum" => 20,
                "item" => %{
                  "sub_icon" => nil,
                  "mod_max_rank" => 3,
                  "icon_format" => "port",
                  "thumb" =>
                    "items/images/en/thumbs/despoil.2633a2c7793d85b21d22cb4c4a0b70cf.128x128.png",
                  "url_name" => "despoil",
                  "icon" => "items/images/en/despoil.2633a2c7793d85b21d22cb4c4a0b70cf.png",
                  "id" => "54e644ffe779897594fa68cd",
                  "tags" => [
                    "mod",
                    "rare",
                    "warframe",
                    "nekros"
                  ],
                  "en" => %{
                    item_name: "Despoil"
                  }
                },
                "creation_date" => "2024-08-12T08:28:26.898+00:00",
                "id" => "66b9c7aa6b17410a57974e4b"
              }
            }
          }

        Plug.Conn.resp(conn, 200, Jason.encode!(response))
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
      user = %UserInfo{ingame_name: "Fl4m3", patreon?: false}

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
      Bypass.expect(bypass, "DELETE", "/v1/profile/orders/:id", fn conn ->
        response = %{"payload" => %{"order_id" => "5ee71a2604d55c0a5cbdc3c2"}}
        Plug.Conn.resp(conn, 200, Jason.encode!(response))
      end)

      placed_order =
        PlacedOrder.new(%{
          "order_id" => "5ee71a2604d55c0a5cbdc3c2",
          "item_id" => "57c73be094b4b0f159ab5e15"
        })

      auth = %Authorization{cookie: "cookie", token: "token"}
      user = %UserInfo{ingame_name: "Fl4m3", patreon?: false}

      :ok = AuctionHouse.update_login(auth, user)
      :ok = AuctionHouse.delete_order(placed_order)

      assert_receive(
        {:delete_order,
         {:ok,
          %PlacedOrder{item_id: "57c73be094b4b0f159ab5e15", order_id: "5ee71a2604d55c0a5cbdc3c2"}}},
        3000
      )
    end
  end

  describe "get_item_orders/1" do
    test "returns order_info if request for orders about item succeeded", %{
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

      :ok = AuctionHouse.get_item_orders("Gleaming Blight")

      assert_receive(
        {:get_item_orders,
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
          ]}},
        3000
      )
    end
  end

  describe "get_user_orders/1" do
    test "returns user orders if request succeeds", %{bypass: bypass} do
      # Arrange
      Bypass.expect(bypass, "GET", "/v1/profile/:username/orders", fn conn ->
        response = %{
          "payload" => %{
            "buy_orders" => [],
            "sell_orders" => [
              %{
                "creation_date" => "2024-03-28T14:47:47.875+00:00",
                "id" => "66058313a9630600302d4889",
                "item" => %{
                  "cs" => %{"item_name" => "Arcane Agility"},
                  "de" => %{"item_name" => "Arkana: Agilität"},
                  "en" => %{"item_name" => "Arcane Agility"},
                  "es" => %{"item_name" => "Agilidad Arcana"},
                  "fr" => %{"item_name" => "Arcane Agilité"},
                  "icon" => "items/images/en/arcane_agility.2274fd115d389b990a55f5a4ff864773.png",
                  "icon_format" => "land",
                  "id" => "55108594e77989728d5100c6",
                  "ko" => %{"item_name" => "아케인 어질리티"},
                  "mod_max_rank" => 5,
                  "pl" => %{"item_name" => "Arkanum Zręczności"},
                  "pt" => %{"item_name" => "Agilidade Arcana"},
                  "ru" => %{"item_name" => "Мистическая Ловкость"},
                  "sub_icon" => nil,
                  "sv" => %{"item_name" => "Arcane Agility"},
                  "tags" => ["uncommon", "arcane_enhancement"],
                  "thumb" =>
                    "items/images/en/thumbs/arcane_agility.2274fd115d389b990a55f5a4ff864773.128x128.png",
                  "uk" => %{"item_name" => "Містична Жвавість"},
                  "url_name" => "arcane_agility",
                  "zh-hans" => %{"item_name" => "赋能·灵敏"},
                  "zh-hant" => %{"item_name" => "靈敏賦能"}
                },
                "last_update" => "2024-03-28T14:47:47.875+00:00",
                "mod_rank" => 0,
                "order_type" => "sell",
                "platform" => "pc",
                "platinum" => 4,
                "quantity" => 21,
                "region" => "en",
                "visible" => true
              },
              %{
                "creation_date" => "2024-03-28T14:48:14.281+00:00",
                "id" => "6605832ea96306003657a90d",
                "item" => %{
                  "cs" => %{"item_name" => "Abating Link"},
                  "de" => %{"item_name" => "Dämpfende Verbindung"},
                  "en" => %{"item_name" => "Abating Link"},
                  "es" => %{"item_name" => "Enlace Mermador"},
                  "fr" => %{"item_name" => "Lien Dégradant"},
                  "icon" => "items/images/en/abating_link.c547fa09315093a5ba6c609a9b195580.png",
                  "icon_format" => "port",
                  "id" => "54e644ffe779897594fa68d2",
                  "ko" => %{"item_name" => "어베이팅 링크"},
                  "mod_max_rank" => 3,
                  "pl" => %{"item_name" => "Osłabiające Połączenie"},
                  "pt" => %{"item_name" => "Abating Link"},
                  "ru" => %{"item_name" => "Ослабляющая Связь"},
                  "sub_icon" => nil,
                  "sv" => %{"item_name" => "Abating Link"},
                  "tags" => ["mod", "rare", "warframe", "trinity"],
                  "thumb" =>
                    "items/images/en/thumbs/abating_link.c547fa09315093a5ba6c609a9b195580.128x128.png",
                  "uk" => %{"item_name" => "Вгамовний Зв’язок"},
                  "url_name" => "abating_link",
                  "zh-hans" => %{"item_name" => "耗弱链接"},
                  "zh-hant" => %{"item_name" => "耗弱連結"}
                },
                "last_update" => "2024-03-28T14:48:14.281+00:00",
                "mod_rank" => 0,
                "order_type" => "sell",
                "platform" => "pc",
                "platinum" => 23,
                "quantity" => 1,
                "region" => "en",
                "visible" => true
              }
            ]
          }
        }

        Plug.Conn.resp(conn, 200, Jason.encode!(response))
      end)

      assert AuctionHouse.get_user_orders("Fl4m3Ph03n1x") == :ok

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
      user = UserInfo.new(%{"ingame_name" => "fl4m3", "patreon?" => false})

      assert :ok == AuctionHouse.update_login(auth, user)
    end
  end

  describe "get_saved_login/0" do
    test "returns server state correctly" do
      # Arrange
      auth = Authorization.new(%{"cookie" => "a_cookie", "token" => "a_token"})
      user = UserInfo.new(%{"ingame_name" => "fl4m3", "patreon?" => false})

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
