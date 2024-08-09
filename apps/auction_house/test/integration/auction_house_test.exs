defmodule AuctionHouseTest do
  @moduledoc false

  use ExUnit.Case, async: false

  alias AuctionHouse
  alias AuctionHouse.Runtime.Server
  alias Bypass
  alias Shared.Data.{Authorization, Credentials, Order, OrderInfo, PlacedOrder, User}
  alias Shared.Data.OrderInfo.User
  alias Shared.Data.User, as: UserInfo

  @test_port 8082

  setup do
    bypass = Bypass.open(port: @test_port)

    {:ok, server} =
      case Server.start_link() do
        {:ok, server} -> {:ok, server}
        {:error, {:already_started, server}} -> {:ok, server}
        err -> err
      end

    %{
      bypass: bypass,
      server: server,
      server_name: AuctionHouse.Runtime.Server_auction_house_integration_test_0
    }
  end

  describe "place_oder/1" do
    test "returns {:ok, placed_order} if order was placed correctly", %{
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
                "thumb" => "icons/en/thumbs/Toxic_Sequence.bab0370da343ca58b4b92fca65b1da6a.128x128.png",
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

      order =
        Order.new(%{
          "order_type" => "sell",
          "item_id" => "54a74454e779892d5e5155d5",
          "platinum" => 15,
          "quantity" => 1,
          "mod_rank" => 0
        })

      login_info = %Authorization{cookie: "cookie", token: "token"}
      :sys.replace_state(server, fn state -> Map.put(state, :authorization, login_info) end)

      # Act
      actual = Server.place_order(order)

      expected =
        {:ok, PlacedOrder.new(%{"item_id" => order.item_id, "order_id" => "5ee71a2604d55c0a5cbdc3c2"})}

      # Assert
      assert actual == expected
    end
  end

  describe "delete_oder/1" do
    test "returns :ok if order was deleted correctly", %{
      bypass: bypass,
      server: server
    } do
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

      login_info = %Authorization{cookie: "cookie", token: "token"}
      :sys.replace_state(server, fn state -> Map.put(state, :authorization, login_info) end)

      # Act
      actual = Server.delete_order(placed_order)
      expected = :ok

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
                  "avatar" => "user/avatar/55d77904e779893a9827aee2.png?9b0eed7b4885f4ec4275240b3035aa55",
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
      actual = Server.get_all_orders(item_name)

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

  describe "login/1" do
    test "returns {:ok, Authorization} when the login is successful", %{
      bypass: bypass
    } do
      # Arrange
      Bypass.expect(bypass, "GET", "/auth/signin", fn conn ->
        body = """
        <!DOCTYPE html>
        <html lang=en>
        <head>
            <meta name="csrf-token" content="a_token">
        </head>
        <body>
        </body>
        </html>
        """

        conn
        |> Plug.Conn.put_resp_header(
          "set-cookie",
          "JWT=old_cookie; Domain=.warframe.market; Expires=Tue, 21-Mar-2023 15:16:03 GMT; Secure; HttpOnly; Path=/; SameSite=Lax"
        )
        |> Plug.Conn.resp(200, body)
      end)

      Bypass.expect(bypass, "POST", "/v1/auth/signin", fn conn ->
        body =
          "{\"payload\": {\"user\": {\"has_mail\": true, \"written_reviews\": 0, \"region\": \"en\", \"banned\": false, \"anonymous\": false, \"role\": \"user\", \"reputation\": 84, \"ingame_name\": \"Fl4m3Ph03n1x\", \"platform\": \"pc\", \"unread_messages\": 0, \"background\": null, \"check_code\": \"66BAPR88DLLZ\", \"avatar\": \"user/avatar/584d425cd3ffb630c3f9df42.png?0a8ad917dc66b85aa69520d70a31dafb\", \"verification\": true, \"linked_accounts\": {\"steam_profile\": true, \"patreon_profile\": false, \"xbox_profile\": false, \"discord_profile\": false, \"github_profile\": false}, \"id\": \"584d425cd3ffb630c3f9df42\", \"locale\": \"en\"}}}"

        conn
        |> Plug.Conn.put_resp_header(
          "set-cookie",
          "JWT=new_cookie; Domain=.warframe.market; Expires=Tue, 21-Mar-2023 14:41:06 GMT; Secure; HttpOnly; Path=/; SameSite=Lax"
        )
        |> Plug.Conn.resp(200, body)
      end)

      credentials = %Credentials{
        email: "an_email",
        password: "password"
      }

      # Act
      actual = Server.login(credentials)

      expected =
        {:ok,
         {
           %Authorization{
             cookie: "JWT=new_cookie",
             token: "a_token"
           },
           %UserInfo{
             patreon?: false,
             ingame_name: "Fl4m3Ph03n1x"
           }
         }}

      # Assert
      assert actual == expected
    end
  end

  describe "recover_login/2" do
    test "updates server state correctly", %{server: server} do
      # Arrange
      auth = Authorization.new(%{"cookie" => "a_cookie", "token" => "a_token"})
      user = UserInfo.new(%{"ingame_name" => "fl4m3", "patreon?" => false})

      # Act
      actual = Server.recover_login(auth, user)
      server_state = :sys.get_state(server)

      # Assert
      assert actual == :ok
      assert Map.get(server_state, :authorization) == auth
      assert Map.get(server_state, :user) == user
    end
  end

  describe "logout/0" do
    test "deletes session correctly", %{server: server, bypass: bypass} do
      # Arrange
      Bypass.expect(bypass, "GET", "/auth/signin", fn conn ->
        body = """
        <!DOCTYPE html>
        <html lang=en>
        <head>
            <meta name="csrf-token" content="a_token">
        </head>
        <body>
        </body>
        </html>
        """

        conn
        |> Plug.Conn.put_resp_header(
          "set-cookie",
          "JWT=old_cookie; Domain=.warframe.market; Expires=Tue, 21-Mar-2023 15:16:03 GMT; Secure; HttpOnly; Path=/; SameSite=Lax"
        )
        |> Plug.Conn.resp(200, body)
      end)

      Bypass.expect(bypass, "POST", "/v1/auth/signin", fn conn ->
        body =
          "{\"payload\": {\"user\": {\"has_mail\": true, \"written_reviews\": 0, \"region\": \"en\", \"banned\": false, \"anonymous\": false, \"role\": \"user\", \"reputation\": 84, \"ingame_name\": \"Fl4m3Ph03n1x\", \"platform\": \"pc\", \"unread_messages\": 0, \"background\": null, \"check_code\": \"66BAPR88DLLZ\", \"avatar\": \"user/avatar/584d425cd3ffb630c3f9df42.png?0a8ad917dc66b85aa69520d70a31dafb\", \"verification\": true, \"linked_accounts\": {\"steam_profile\": true, \"patreon_profile\": false, \"xbox_profile\": false, \"discord_profile\": false, \"github_profile\": false}, \"id\": \"584d425cd3ffb630c3f9df42\", \"locale\": \"en\"}}}"

        conn
        |> Plug.Conn.put_resp_header(
          "set-cookie",
          "JWT=new_cookie; Domain=.warframe.market; Expires=Tue, 21-Mar-2023 14:41:06 GMT; Secure; HttpOnly; Path=/; SameSite=Lax"
        )
        |> Plug.Conn.resp(200, body)
      end)

      credentials = %Credentials{
        email: "an_email",
        password: "password"
      }

      Server.login(credentials)

      # Act
      actual = Server.logout()
      server_state = :sys.get_state(server)

      # Assert
      assert actual == :ok
      assert Map.get(server_state, :authorization) == nil
      assert Map.get(server_state, :user) == nil
    end
  end

  describe "get_user_orders/2" do
    test "returns {:ok, [placed_order]} if request for currently listed user orders succeeded", %{
      bypass: bypass
    } do
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
                  "thumb" => "items/images/en/thumbs/arcane_agility.2274fd115d389b990a55f5a4ff864773.128x128.png",
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
                  "thumb" => "items/images/en/thumbs/abating_link.c547fa09315093a5ba6c609a9b195580.128x128.png",
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

      username = "Fl4m3Ph03n1x"

      # Act
      actual = Server.get_user_orders(username)

      expected =
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
         ]}

      # Assert
      assert actual == expected
    end
  end
end
