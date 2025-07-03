defmodule Manager.WorkerTest do
  @moduledoc false

  use ExUnit.Case, async: false

  alias Helpers
  alias Manager.Runtime.ManagerSupervisor
  alias Plug.Conn
  alias Shared.Data.{Authorization, Credentials, Strategy, User}

  @timeout 5_000

  ##########
  # Setup  #
  ##########

  @watch_list_file :store |> Application.compile_env!(:watch_list) |> Path.join()
  @setup_file :store |> Application.compile_env!(:setup) |> Path.join()

  defp create_watch_list_file(active_syndicates) when is_map(active_syndicates) do
    content = Jason.encode!(%{active_syndicates: active_syndicates})

    File.write(@watch_list_file, content)
  end

  defp reset_watch_list_file, do: create_watch_list_file(%{})

  defp create_setup_file do
    content =
      Jason.encode!(%{
        authorization: %{
          cookie: "a_cookie",
          token: "a_token"
        },
        user: %{
          ingame_name: "fl4m3",
          patreon?: false
        }
      })

    File.write(@setup_file, content)
  end

  defp reset_setup_file do
    content =
      Jason.encode!(%{
        authorization: %{},
        user: %{}
      })

    File.write(@setup_file, content)
  end

  ##########
  # Tests  #
  ##########

  describe "activate" do
    setup do
      create_setup_file()
      create_watch_list_file(%{})

      on_exit(fn ->
        reset_setup_file()
        reset_watch_list_file()
      end)

      bypass = Bypass.open(port: 8082)
      credentials = Credentials.new("an_email", "a_password")
      user = User.new(%{"ingame_name" => "fl4m3", "patreon?" => false})

      Bypass.stub(bypass, "GET", "/auth/signin", fn conn ->
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

      Bypass.stub(bypass, "POST", "/v1/auth/signin", fn conn ->
        body =
          "{\"payload\": {\"user\": {\"has_mail\": true, \"written_reviews\": 0, \"region\": \"en\", \"banned\": false, \"anonymous\": false, \"role\": \"user\", \"reputation\": 84, \"ingame_name\": \"Fl4m3Ph03n1x\", \"platform\": \"pc\", \"unread_messages\": 0, \"background\": null, \"check_code\": \"66BAPR88DLLZ\", \"avatar\": \"user/avatar/584d425cd3ffb630c3f9df42.png?0a8ad917dc66b85aa69520d70a31dafb\", \"verification\": true, \"linked_accounts\": {\"steam_profile\": true, \"patreon_profile\": false, \"xbox_profile\": false, \"discord_profile\": false, \"github_profile\": false}, \"id\": \"584d425cd3ffb630c3f9df42\", \"locale\": \"en\"}}}"

        conn
        |> Plug.Conn.put_resp_header(
          "Set-Cookie",
          "JWT=new_cookie; Domain=.warframe.market; Expires=Tue, 21-Mar-2023 14:41:06 GMT; Secure; HttpOnly; Path=/; SameSite=Lax"
        )
        |> Plug.Conn.resp(200, body)
      end)

      _manager_pid = start_supervised(ManagerSupervisor)
      :ok = Manager.login(credentials, false)

      assert_receive({:login, {:ok, %User{patreon?: false, ingame_name: "fl4m3"}}}, @timeout)

      %{
        user: user,
        bypass: bypass
      }
    end

    test "activates multiple syndicates with the given strategies", %{bypass: bypass} do
      # get current orders
      Bypass.expect_once(bypass, "GET", "/v1/profile/fl4m3/orders", fn conn ->
        body = """
          {
            "payload": {
              "sell_orders": [
                  {
                      "region": "en",
                      "order_type": "sell",
                      "mod_rank": 0,
                      "id": "677f90f6a8a4b1000937d1bb",
                      "quantity": 1,
                      "visible": true,
                      "item": {
                          "icon_format": "port",
                          "tags": [
                              "mod",
                              "rare",
                              "warframe",
                              "trinity"
                          ],
                          "mod_max_rank": 3,
                          "id": "54e644ffe779897594fa68d2",
                          "sub_icon": null,
                          "icon": "items/images/en/abating_link.c547fa09315093a5ba6c609a9b195580.png",
                          "thumb": "items/images/en/thumbs/abating_link.c547fa09315093a5ba6c609a9b195580.128x128.png",
                          "url_name": "abating_link",
                          "en": {
                              "item_name": "Abating Link"
                          },
                          "ru": {
                              "item_name": "Ослабляющая Связь"
                          },
                          "ko": {
                              "item_name": "어베이팅 링크"
                          },
                          "fr": {
                              "item_name": "Lien Dégradant"
                          },
                          "sv": {
                              "item_name": "Abating Link"
                          },
                          "de": {
                              "item_name": "Dämpfende Verbindung"
                          },
                          "zh-hant": {
                              "item_name": "耗弱連結"
                          },
                          "zh-hans": {
                              "item_name": "耗弱链接"
                          },
                          "pt": {
                              "item_name": "Elo Redutivo"
                          },
                          "es": {
                              "item_name": "Enlace Mermador"
                          },
                          "pl": {
                              "item_name": "Osłabiające Połączenie"
                          },
                          "cs": {
                              "item_name": "Abating Link"
                          },
                          "uk": {
                              "item_name": "Вгамовний Зв’язок"
                          }
                      },
                      "platinum": 15,
                      "creation_date": "2025-01-09T09:03:50.271+00:00",
                      "last_update": "2025-01-09T09:03:50.271+00:00",
                      "platform": "pc"
                  }
              ],
              "buy_orders": []
            }
          }
        """

        conn
        |> Conn.put_resp_header(
          "Set-Cookie",
          "JWT=old_cookie; Domain=.warframe.market; Expires=Tue, 21-Mar-2023 15:16:03 GMT; Secure; HttpOnly; Path=/; SameSite=Lax"
        )
        |> Conn.put_resp_header("content-type", "application/json")
        |> Conn.resp(200, body)
      end)

      # get current sell order for item
      Bypass.expect_once(bypass, "GET", "/v1/items/scattered_justice/orders", fn conn ->
        body = """
        {
          "payload": {
              "orders": [
                  {
                      "creation_date": "2017-09-19T02:01:29.000+00:00",
                      "visible": true,
                      "quantity": 1,
                      "user": {
                          "reputation": 1977,
                          "locale": "en",
                          "avatar": "user/avatar/5678a156cbfa8f02c9b814c3.png?0d832d1017240078ecf4bdeb0d08a101",
                          "ingame_name": "Ealirinineomh",
                          "last_seen": "2025-01-13T04:21:53.899+00:00",
                          "crossplay": false,
                          "platform": "pc",
                          "id": "5678a156cbfa8f02c9b814c3",
                          "region": "en",
                          "status": "online"
                      },
                      "last_update": "2019-11-24T01:58:58.000+00:00",
                      "platinum": 18,
                      "order_type": "sell",
                      "id": "59c07a790f31396e83ed709b",
                      "mod_rank": 0,
                      "region": "en"
                  },
                  {
                      "order_type": "sell",
                      "last_update": "2021-08-23T07:28:38.000+00:00",
                      "user": {
                          "reputation": 262,
                          "locale": "en",
                          "avatar": "user/avatar/599d52da0f313979a13fad96.png?4499006929224dac2b142b9e246d76c4",
                          "ingame_name": "ElysiumLeoSK",
                          "last_seen": "2025-01-10T16:48:28.224+00:00",
                          "crossplay": false,
                          "platform": "pc",
                          "id": "599d52da0f313979a13fad96",
                          "region": "en",
                          "status": "ingame"
                      },
                      "quantity": 1,
                      "creation_date": "2018-01-09T07:07:17.000+00:00",
                      "visible": true,
                      "platinum": 15,
                      "id": "5a546a25d1d7bb035fec97c1",
                      "mod_rank": 0,
                      "region": "en"
                  },
                  {
                      "last_update": "2025-01-11T08:36:52.000+00:00",
                      "quantity": 1,
                      "user": {
                          "reputation": 18,
                          "locale": "en",
                          "avatar": null,
                          "last_seen": "2025-01-13T08:14:49.114+00:00",
                          "ingame_name": "Evilwarboss",
                          "crossplay": false,
                          "platform": "pc",
                          "id": "5a18b506089425052e4cb592",
                          "region": "en",
                          "status": "ingame"
                      },
                      "creation_date": "2018-07-25T03:41:00.000+00:00",
                      "order_type": "sell",
                      "platinum": 10,
                      "visible": true,
                      "id": "5b57f14cb15db0042d1fcf29",
                      "mod_rank": 0,
                      "region": "en"
                  }
              ]
          }
        }
        """

        conn
        |> Plug.Conn.put_resp_header(
          "Set-Cookie",
          "JWT=old_cookie; Domain=.warframe.market; Expires=Tue, 21-Mar-2023 15:16:03 GMT; Secure; HttpOnly; Path=/; SameSite=Lax"
        )
        |> Conn.put_resp_header("content-type", "application/json")
        |> Plug.Conn.resp(200, body)
      end)

      # get current sell order for item
      Bypass.expect_once(bypass, "GET", "/v1/items/justice_blades/orders", fn conn ->
        body = """
        {
          "payload": {
              "orders": [
                  {
                      "creation_date": "2017-08-12T21:42:28.000+00:00",
                      "visible": true,
                      "quantity": 1,
                      "user": {
                          "reputation": 1977,
                          "locale": "en",
                          "avatar": "user/avatar/5678a156cbfa8f02c9b814c3.png?0d832d1017240078ecf4bdeb0d08a101",
                          "ingame_name": "Ealirinineomh",
                          "last_seen": "2025-01-13T04:21:53.899+00:00",
                          "crossplay": false,
                          "platform": "pc",
                          "id": "5678a156cbfa8f02c9b814c3",
                          "region": "en",
                          "status": "online"
                      },
                      "last_update": "2019-11-24T01:58:47.000+00:00",
                      "platinum": 18,
                      "order_type": "sell",
                      "id": "598f76440f313951e3167944",
                      "mod_rank": 0,
                      "region": "en"
                  },
                  {
                      "order_type": "sell",
                      "visible": true,
                      "creation_date": "2018-07-25T03:40:35.000+00:00",
                      "platinum": 10,
                      "quantity": 1,
                      "last_update": "2023-02-09T17:31:17.000+00:00",
                      "user": {
                          "reputation": 18,
                          "locale": "en",
                          "avatar": null,
                          "last_seen": "2025-01-13T08:14:49.114+00:00",
                          "ingame_name": "Evilwarboss",
                          "crossplay": false,
                          "platform": "pc",
                          "id": "5a18b506089425052e4cb592",
                          "region": "en",
                          "status": "online"
                      },
                      "id": "5b57f1332550e9041b8d9c8a",
                      "mod_rank": 0,
                      "region": "en"
                  },
                  {
                      "order_type": "sell",
                      "quantity": 1,
                      "platinum": 20,
                      "visible": true,
                      "user": {
                          "reputation": 0,
                          "platform": "pc",
                          "crossplay": false,
                          "locale": "en",
                          "avatar": null,
                          "last_seen": "2025-01-13T10:08:00.346+00:00",
                          "ingame_name": "Ticklezz",
                          "id": "675f493c39f475004213f4cc",
                          "region": "en",
                          "status": "ingame"
                      },
                      "creation_date": "2025-01-12T21:04:06.000+00:00",
                      "last_update": "2025-01-13T07:44:22.000+00:00",
                      "id": "67842e4671aa440009ee3492",
                      "mod_rank": 3,
                      "region": "en"
                  }
              ]
          }
        }
        """

        conn
        |> Plug.Conn.put_resp_header(
          "Set-Cookie",
          "JWT=old_cookie; Domain=.warframe.market; Expires=Tue, 21-Mar-2023 15:16:03 GMT; Secure; HttpOnly; Path=/; SameSite=Lax"
        )
        |> Conn.put_resp_header("content-type", "application/json")
        |> Plug.Conn.resp(200, body)
      end)

      # get current sell order for item
      Bypass.expect_once(bypass, "GET", "/v1/items/gilded_truth/orders", fn conn ->
        body = """
        {
            "payload": {
                "orders": [
                    {
                        "order_type": "sell",
                        "platinum": 12,
                        "quantity": 1,
                        "user": {
                            "reputation": 36,
                            "locale": "en",
                            "avatar": "user/avatar/5b7bf16cdebecf04373da2bf.png?c2bda0157a8c8e48f01648ca9866d3be",
                            "last_seen": "2025-01-13T02:58:09.665+00:00",
                            "ingame_name": "tevinskii",
                            "crossplay": false,
                            "platform": "pc",
                            "id": "5b7bf16cdebecf04373da2bf",
                            "region": "en",
                            "status": "ingame"
                        },
                        "creation_date": "2018-09-18T07:33:06.000+00:00",
                        "last_update": "2024-12-07T08:04:08.000+00:00",
                        "visible": true,
                        "id": "5ba0aa3217f2f2014f4344e2",
                        "mod_rank": 0,
                        "region": "en"
                    },
                    {
                        "order_type": "sell",
                        "quantity": 1,
                        "platinum": 100,
                        "user": {
                            "reputation": 1027,
                            "locale": "en",
                            "avatar": "user/avatar/5686d3e3cbfa8f12f73672f1.png?4c3f058d716e3513efb955759d2049de",
                            "ingame_name": "-BM-SniperKitten",
                            "last_seen": "2025-01-13T02:21:38.247+00:00",
                            "crossplay": false,
                            "platform": "pc",
                            "id": "5686d3e3cbfa8f12f73672f1",
                            "region": "en",
                            "status": "online"
                        },
                        "creation_date": "2019-09-04T12:41:10.000+00:00",
                        "last_update": "2024-03-18T06:44:17.000+00:00",
                        "visible": true,
                        "id": "5d6fb0e6934a4d035b797593",
                        "mod_rank": 3,
                        "region": "en"
                    },
                    {
                        "quantity": 1,
                        "order_type": "sell",
                        "platinum": 14,
                        "user": {
                            "reputation": 5,
                            "locale": "en",
                            "avatar": null,
                            "last_seen": "2025-01-13T06:31:53.982+00:00",
                            "ingame_name": "stinkydoge773",
                            "crossplay": false,
                            "platform": "pc",
                            "id": "5b306745c34b920652b5bfb4",
                            "region": "en",
                            "status": "ingame"
                        },
                        "creation_date": "2020-07-13T05:02:43.000+00:00",
                        "last_update": "2020-07-13T22:20:31.000+00:00",
                        "visible": true,
                        "id": "5f0beaf3d48cbd016e5e20e8",
                        "mod_rank": 0,
                        "region": "en"
                    }
                ]
            }
        }
        """

        conn
        |> Plug.Conn.put_resp_header(
          "Set-Cookie",
          "JWT=old_cookie; Domain=.warframe.market; Expires=Tue, 21-Mar-2023 15:16:03 GMT; Secure; HttpOnly; Path=/; SameSite=Lax"
        )
        |> Conn.put_resp_header("content-type", "application/json")
        |> Plug.Conn.resp(200, body)
      end)

      # get current sell order for item
      Bypass.expect_once(bypass, "GET", "/v1/items/blade_of_truth/orders", fn conn ->
        body = """
        {
            "payload": {
                "orders": [
                    {
                        "quantity": 10,
                        "platinum": 19,
                        "order_type": "sell",
                        "user": {
                            "reputation": 32,
                            "locale": "en",
                            "avatar": "user/avatar/5aa2b01449ef000cb71214f7.png?298c6d87e287773609cc9db362372bf3",
                            "last_seen": "2025-01-13T09:26:11.288+00:00",
                            "ingame_name": "PrimedDaniel",
                            "crossplay": false,
                            "platform": "pc",
                            "id": "5aa2b01449ef000cb71214f7",
                            "region": "en",
                            "status": "offline"
                        },
                        "creation_date": "2019-07-22T16:45:59.000+00:00",
                        "last_update": "2025-01-06T14:24:28.000+00:00",
                        "visible": true,
                        "id": "5d35e847efe513024f0a7f10",
                        "mod_rank": 0,
                        "region": "en"
                    },
                    {
                        "order_type": "sell",
                        "quantity": 1,
                        "platinum": 100,
                        "user": {
                            "reputation": 1027,
                            "locale": "en",
                            "avatar": "user/avatar/5686d3e3cbfa8f12f73672f1.png?4c3f058d716e3513efb955759d2049de",
                            "ingame_name": "-BM-SniperKitten",
                            "last_seen": "2025-01-13T02:21:38.247+00:00",
                            "crossplay": false,
                            "platform": "pc",
                            "id": "5686d3e3cbfa8f12f73672f1",
                            "region": "en",
                            "status": "offline"
                        },
                        "creation_date": "2019-09-04T12:40:39.000+00:00",
                        "last_update": "2024-03-18T06:45:20.000+00:00",
                        "visible": true,
                        "id": "5d6fb0c7b6afee035a643e7b",
                        "mod_rank": 3,
                        "region": "en"
                    },
                    {
                        "platinum": 14,
                        "quantity": 6,
                        "order_type": "sell",
                        "user": {
                            "reputation": 111,
                            "locale": "en",
                            "avatar": "user/avatar/5d826e71879286050eebfc76.png?cadedd0ef194b4edd8ac3ed64d3cfbdb",
                            "last_seen": "2025-01-13T10:33:21.964+00:00",
                            "ingame_name": "Skyz72",
                            "crossplay": false,
                            "platform": "pc",
                            "id": "5d826e71879286050eebfc76",
                            "region": "en",
                            "status": "offline"
                        },
                        "creation_date": "2020-01-05T20:14:15.000+00:00",
                        "last_update": "2025-01-10T11:52:32.000+00:00",
                        "visible": true,
                        "id": "5e124397145697056201a5cd",
                        "mod_rank": 3,
                        "region": "en"
                    }
                ]
            }
        }
        """

        conn
        |> Plug.Conn.put_resp_header(
          "Set-Cookie",
          "JWT=old_cookie; Domain=.warframe.market; Expires=Tue, 21-Mar-2023 15:16:03 GMT; Secure; HttpOnly; Path=/; SameSite=Lax"
        )
        |> Conn.put_resp_header("content-type", "application/json")
        |> Plug.Conn.resp(200, body)
      end)

      # post orders online
      Bypass.expect(bypass, "POST", "/v1/profile/orders", fn conn ->
        {:ok, req_body, _req_conn} = Plug.Conn.read_body(conn)
        decoded_request = Jason.decode!(req_body)

        response_body =
          case decoded_request do
            %{
              "item_id" => "54a74454e779892d5e5155f5",
              "order_type" => "sell",
              "platinum" => 14,
              "quantity" => 1,
              "mod_rank" => 0
            } ->
              """
              {
                "payload": {
                  "order": {
                  "last_update": "2025-01-10T15:29:18.242+00:00",
                  "id": "67813cce093d4c0009d3445e",
                  "region": "en",
                  "mod_rank": 0,
                  "creation_date": "2025-01-10T15:29:18.242+00:00",
                  "item": {
                    "mod_max_rank": 3,
                    "id": "54a74454e779892d5e5155f5",
                    "url_name": "scattered_justice",
                    "icon": "items/images/en/scattered_justice.b46113ecdbc04d327240cedec0e3b1f1.png",
                    "thumb": "items/images/en/thumbs/scattered_justice.b46113ecdbc04d327240cedec0e3b1f1.128x128.png",
                    "icon_format": "port",
                    "tags": [
                        "syndicate",
                        "mod",
                        "rare",
                        "primary",
                        "hek"
                    ],
                    "sub_icon": null,
                    "en": {
                        "item_name": "Scattered Justice"
                    },
                    "ru": {
                        "item_name": "Переменная Справедливость"
                    },
                    "ko": {
                        "item_name": "스캐터드 저스티스"
                    },
                    "fr": {
                        "item_name": "Justice Dispersée"
                    },
                    "sv": {
                        "item_name": "Scattered Justice"
                    },
                    "de": {
                        "item_name": "Zerstreute Gerechtigkeit"
                    },
                    "zh-hant": {
                        "item_name": "散射正義"
                    },
                    "zh-hans": {
                        "item_name": "散射正义"
                    },
                    "pt": {
                        "item_name": "Scattered Justice"
                    },
                    "es": {
                        "item_name": "Justicia Dispersa"
                    },
                    "pl": {
                        "item_name": "Rozproszona Sprawiedliwość"
                    },
                    "cs": {
                        "item_name": "Scattered Justice"
                    },
                    "uk": {
                        "item_name": "Розсіяне Правосуддя"
                    },
                    "it": {
                        "item_name": "Scattered Justice"
                    }
                  },
                  "quantity": 1,
                  "visible": true,
                  "platinum": 16,
                  "order_type": "sell",
                  "platform": "pc"
                  }
                }
              }
              """

            %{
              "item_id" => "54a74454e779892d5e515645",
              "order_type" => "sell",
              "platinum" => 16,
              "quantity" => 1,
              "mod_rank" => 0
            } ->
              """
              {
              "payload": {
                  "order": {
                      "last_update": "2025-01-10T15:33:51.481+00:00",
                      "region": "en",
                      "creation_date": "2025-01-10T15:33:51.481+00:00",
                      "item": {
                          "tags": [
                              "syndicate",
                              "mod",
                              "melee",
                              "rare",
                              "jaw_sword"
                          ],
                          "icon_format": "port",
                          "url_name": "blade_of_truth",
                          "icon": "items/images/en/blade_of_truth.53d68caa8f7ae06642b2ed1fd8f3b6cd.png",
                          "thumb": "items/images/en/thumbs/blade_of_truth.53d68caa8f7ae06642b2ed1fd8f3b6cd.128x128.png",
                          "id": "54a74454e779892d5e515645",
                          "sub_icon": null,
                          "mod_max_rank": 3,
                          "en": {
                              "item_name": "Blade Of Truth"
                          },
                          "ru": {
                              "item_name": "Клинок Правды"
                          },
                          "ko": {
                              "item_name": "블레이드 오브 트루스"
                          },
                          "fr": {
                              "item_name": "Lames De La Vérité"
                          },
                          "sv": {
                              "item_name": "Blade Of Truth"
                          },
                          "de": {
                              "item_name": "Klinge Der Wahrheit"
                          },
                          "zh-hant": {
                              "item_name": "真相之刃"
                          },
                          "zh-hans": {
                              "item_name": "真相之刃"
                          },
                          "pt": {
                              "item_name": "Blade Of Truth"
                          },
                          "es": {
                              "item_name": "Hoja De La Verdad"
                          },
                          "pl": {
                              "item_name": "Ostrze Prawdy"
                          },
                          "cs": {
                              "item_name": "Blade Of Truth"
                          },
                          "uk": {
                              "item_name": "Лезо Правди"
                          },
                          "it": {
                              "item_name": "Blade Of Truth"
                          }
                      },
                      "visible": true,
                      "mod_rank": 0,
                      "platinum": 16,
                      "quantity": 1,
                      "id": "67813ddf3ba9d800083a54b8",
                      "order_type": "sell",
                      "platform": "pc"
                  }
                }
              }
              """

            %{
              "item_id" => "54a74454e779892d5e515664",
              "order_type" => "sell",
              "platinum" => 14,
              "quantity" => 1,
              "mod_rank" => 0
            } ->
              """
              {
                "payload": {
                    "order": {
                        "last_update": "2025-01-10T15:36:10.778+00:00",
                        "id": "67813e6a093d4c000bae6f8a",
                        "region": "en",
                        "mod_rank": 0,
                        "creation_date": "2025-01-10T15:36:10.778+00:00",
                        "item": {
                            "mod_max_rank": 3,
                            "id": "54a74454e779892d5e515664",
                            "url_name": "gilded_truth",
                            "icon": "items/images/en/gilded_truth.4f864f82b65bf77a28c01419c6cbfce1.png",
                            "thumb": "items/images/en/thumbs/gilded_truth.4f864f82b65bf77a28c01419c6cbfce1.128x128.png",
                            "icon_format": "port",
                            "tags": [
                                "syndicate",
                                "burston_prime",
                                "mod",
                                "rare",
                                "primary",
                                "prime"
                            ],
                            "sub_icon": null,
                            "en": {
                                "item_name": "Gilded Truth"
                            },
                            "ru": {
                                "item_name": "Позолоченная Правда"
                            },
                            "ko": {
                                "item_name": "길디드 트루스"
                            },
                            "fr": {
                                "item_name": "Vérité Dorée"
                            },
                            "sv": {
                                "item_name": "Gilded Truth"
                            },
                            "de": {
                                "item_name": "Vergoldete Wahrheit"
                            },
                            "zh-hant": {
                                "item_name": "鍍金真相"
                            },
                            "zh-hans": {
                                "item_name": "镀金真相"
                            },
                            "pt": {
                                "item_name": "Gilded Truth"
                            },
                            "es": {
                                "item_name": "Verdad Dorada"
                            },
                            "pl": {
                                "item_name": "Pozłacana Prawda"
                            },
                            "cs": {
                                "item_name": "Gilded Truth"
                            },
                            "uk": {
                                "item_name": "Позолочена Правда"
                            },
                            "it": {
                                "item_name": "Gilded Truth"
                            }
                        },
                        "quantity": 1,
                        "visible": true,
                        "platinum": 16,
                        "order_type": "sell",
                        "platform": "pc"
                    }
                }
              }
              """

            %{
              "item_id" => "54a74455e779892d5e5156b9",
              "order_type" => "sell",
              "platinum" => 20,
              "quantity" => 1,
              "mod_rank" => 0
            } ->
              """
              {
                "payload": {
                    "order": {
                        "last_update": "2025-01-10T15:37:20.300+00:00",
                        "item": {
                            "icon_format": "port",
                            "url_name": "justice_blades",
                            "icon": "items/images/en/justice_blades.465e02b8fa93e85a73dd5aa83e0808fb.png",
                            "sub_icon": null,
                            "thumb": "items/images/en/thumbs/justice_blades.465e02b8fa93e85a73dd5aa83e0808fb.128x128.png",
                            "id": "54a74455e779892d5e5156b9",
                            "tags": [
                                "syndicate",
                                "dual_cleavers",
                                "mod",
                                "melee",
                                "rare"
                            ],
                            "mod_max_rank": 3,
                            "en": {
                                "item_name": "Justice Blades"
                            },
                            "ru": {
                                "item_name": "Лезвия Справедливости"
                            },
                            "ko": {
                                "item_name": "저스티스 블레이드"
                            },
                            "fr": {
                                "item_name": "Lames Justicières"
                            },
                            "sv": {
                                "item_name": "Justice Blades"
                            },
                            "de": {
                                "item_name": "Gerechtigkeits-Klinge"
                            },
                            "zh-hant": {
                                "item_name": "正義刀鋒"
                            },
                            "zh-hans": {
                                "item_name": "正义刀锋"
                            },
                            "pt": {
                                "item_name": "Justice Blades"
                            },
                            "es": {
                                "item_name": "Hojas De Justicia"
                            },
                            "pl": {
                                "item_name": "Ostrza Sprawiedliwości"
                            },
                            "cs": {
                                "item_name": "Justice Blades"
                            },
                            "uk": {
                                "item_name": "Леза Правосуддя"
                            },
                            "it": {
                                "item_name": "Justice Blades"
                            }
                        },
                        "region": "en",
                        "order_type": "sell",
                        "creation_date": "2025-01-10T15:37:20.300+00:00",
                        "mod_rank": 0,
                        "quantity": 1,
                        "id": "67813eb0862c1d00070f9a57",
                        "platinum": 16,
                        "visible": true,
                        "platform": "pc"
                    }
                }
              }
              """

            _ ->
              throw("Unknown request body: #{req_body}")
          end

        conn
        |> Plug.Conn.put_resp_header(
          "Set-Cookie",
          "JWT=old_cookie; Domain=.warframe.market; Expires=Tue, 21-Mar-2023 15:16:03 GMT; Secure; HttpOnly; Path=/; SameSite=Lax"
        )
        |> Conn.put_resp_header("content-type", "application/json")
        |> Plug.Conn.resp(200, response_body)
      end)

      :ok = Manager.activate(%{steel_meridian: :top_five_average, arbiters_of_hexis: :top_three_average})
      assert_receive({:activate, {:ok, :get_user_orders}}, @timeout)
      assert_receive({:activate, {:ok, :calculating_item_prices}}, @timeout)
      assert_receive({:activate, {:ok, {:price_calculated, "Scattered Justice", 14, 1, 4}}}, @timeout)
      assert_receive({:activate, {:ok, {:price_calculated, "Blade of Truth", 16, 2, 4}}}, @timeout)
      assert_receive({:activate, {:ok, {:price_calculated, "Gilded Truth", 14, 3, 4}}}, @timeout)
      assert_receive({:activate, {:ok, {:price_calculated, "Justice Blades", 20, 4, 4}}}, @timeout)
      assert_receive({:activate, {:ok, :placing_orders}}, @timeout)
      assert_receive({:activate, {:ok, {:order_placed, "Scattered Justice", 1, 4}}}, @timeout)
      assert_receive({:activate, {:ok, {:order_placed, "Blade of Truth", 2, 4}}}, @timeout)
      assert_receive({:activate, {:ok, {:order_placed, "Gilded Truth", 3, 4}}}, @timeout)
      assert_receive({:activate, {:ok, {:order_placed, "Justice Blades", 4, 4}}}, @timeout)
      assert_receive({:activate, {:ok, :done}}, @timeout)

      assert Manager.active_syndicates() ==
               {:ok, %{steel_meridian: :top_five_average, arbiters_of_hexis: :top_three_average}}
    end
  end

  describe "deactivate" do
    setup do
      create_setup_file()

      create_watch_list_file(%{
        steel_meridian: :top_three_average,
        arbiters_of_hexis: :top_five_average,
        cephalon_suda: :lowest_minus_one
      })

      on_exit(fn ->
        reset_setup_file()
        reset_watch_list_file()
      end)

      bypass = Bypass.open(port: 8082)
      credentials = Credentials.new("an_email", "a_password")
      user = User.new(%{"ingame_name" => "fl4m3", "patreon?" => false})

      Bypass.stub(bypass, "GET", "/auth/signin", fn conn ->
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

      Bypass.stub(bypass, "POST", "/v1/auth/signin", fn conn ->
        body =
          "{\"payload\": {\"user\": {\"has_mail\": true, \"written_reviews\": 0, \"region\": \"en\", \"banned\": false, \"anonymous\": false, \"role\": \"user\", \"reputation\": 84, \"ingame_name\": \"Fl4m3Ph03n1x\", \"platform\": \"pc\", \"unread_messages\": 0, \"background\": null, \"check_code\": \"66BAPR88DLLZ\", \"avatar\": \"user/avatar/584d425cd3ffb630c3f9df42.png?0a8ad917dc66b85aa69520d70a31dafb\", \"verification\": true, \"linked_accounts\": {\"steam_profile\": true, \"patreon_profile\": false, \"xbox_profile\": false, \"discord_profile\": false, \"github_profile\": false}, \"id\": \"584d425cd3ffb630c3f9df42\", \"locale\": \"en\"}}}"

        conn
        |> Plug.Conn.put_resp_header(
          "Set-Cookie",
          "JWT=new_cookie; Domain=.warframe.market; Expires=Tue, 21-Mar-2023 14:41:06 GMT; Secure; HttpOnly; Path=/; SameSite=Lax"
        )
        |> Plug.Conn.resp(200, body)
      end)

      _manager_pid = start_supervised(ManagerSupervisor)
      :ok = Manager.login(credentials, false)

      assert_receive({:login, {:ok, %User{patreon?: false, ingame_name: "fl4m3"}}}, @timeout)

      %{
        user: user,
        bypass: bypass
      }
    end

    test "deactivate some syndicates that are active and reactivates the remaining ones", %{bypass: bypass} do
      Bypass.expect(bypass, "GET", "/v1/profile/fl4m3/orders", fn conn ->
        body =
          """
          {
              "payload": {
                  "sell_orders": [
                      {
                          "id": "678549e7093d4c0008f12149",
                          "item": {
                              "mod_max_rank": 3,
                              "id": "54a74454e779892d5e5155f5",
                              "url_name": "scattered_justice",
                              "icon": "items/images/en/scattered_justice.b46113ecdbc04d327240cedec0e3b1f1.png",
                              "thumb": "items/images/en/thumbs/scattered_justice.b46113ecdbc04d327240cedec0e3b1f1.128x128.png",
                              "sub_icon": null,
                              "tags": [
                                  "syndicate",
                                  "mod",
                                  "rare",
                                  "primary",
                                  "hek"
                              ],
                              "icon_format": "port",
                              "en": {
                                  "item_name": "Scattered Justice"
                              },
                              "ru": {
                                  "item_name": "Переменная Справедливость"
                              },
                              "ko": {
                                  "item_name": "스캐터드 저스티스"
                              },
                              "fr": {
                                  "item_name": "Justice Dispersée"
                              },
                              "sv": {
                                  "item_name": "Scattered Justice"
                              },
                              "de": {
                                  "item_name": "Zerstreute Gerechtigkeit"
                              },
                              "zh-hant": {
                                  "item_name": "散射正義"
                              },
                              "zh-hans": {
                                  "item_name": "散射正义"
                              },
                              "pt": {
                                  "item_name": "Scattered Justice"
                              },
                              "es": {
                                  "item_name": "Justicia Dispersa"
                              },
                              "pl": {
                                  "item_name": "Rozproszona Sprawiedliwość"
                              },
                              "cs": {
                                  "item_name": "Scattered Justice"
                              },
                              "uk": {
                                  "item_name": "Розсіяне Правосуддя"
                              },
                              "it": {
                                  "item_name": "Scattered Justice"
                              }
                          },
                          "platinum": 15,
                          "quantity": 1,
                          "visible": true,
                          "creation_date": "2025-01-13T17:14:15.163+00:00",
                          "last_update": "2025-01-13T17:14:15.163+00:00",
                          "mod_rank": 0,
                          "order_type": "sell",
                          "region": "en",
                          "platform": "pc"
                      },
                      {
                          "id": "67854a1371aa440007eb3de9",
                          "item": {
                              "mod_max_rank": 3,
                              "id": "54a74455e779892d5e5156b9",
                              "url_name": "justice_blades",
                              "icon": "items/images/en/justice_blades.465e02b8fa93e85a73dd5aa83e0808fb.png",
                              "thumb": "items/images/en/thumbs/justice_blades.465e02b8fa93e85a73dd5aa83e0808fb.128x128.png",
                              "sub_icon": null,
                              "tags": [
                                  "syndicate",
                                  "dual_cleavers",
                                  "mod",
                                  "melee",
                                  "rare"
                              ],
                              "icon_format": "port",
                              "en": {
                                  "item_name": "Justice Blades"
                              },
                              "ru": {
                                  "item_name": "Лезвия Справедливости"
                              },
                              "ko": {
                                  "item_name": "저스티스 블레이드"
                              },
                              "fr": {
                                  "item_name": "Lames Justicières"
                              },
                              "sv": {
                                  "item_name": "Justice Blades"
                              },
                              "de": {
                                  "item_name": "Gerechtigkeits-Klinge"
                              },
                              "zh-hant": {
                                  "item_name": "正義刀鋒"
                              },
                              "zh-hans": {
                                  "item_name": "正义刀锋"
                              },
                              "pt": {
                                  "item_name": "Justice Blades"
                              },
                              "es": {
                                  "item_name": "Hojas De Justicia"
                              },
                              "pl": {
                                  "item_name": "Ostrza Sprawiedliwości"
                              },
                              "cs": {
                                  "item_name": "Justice Blades"
                              },
                              "uk": {
                                  "item_name": "Леза Правосуддя"
                              },
                              "it": {
                                  "item_name": "Justice Blades"
                              }
                          },
                          "platinum": 16,
                          "quantity": 1,
                          "visible": true,
                          "creation_date": "2025-01-13T17:14:59.134+00:00",
                          "last_update": "2025-01-13T17:14:59.134+00:00",
                          "mod_rank": 0,
                          "order_type": "sell",
                          "region": "en",
                          "platform": "pc"
                      },
                      {
                          "id": "67854a303ba9d80007de3e5d",
                          "item": {
                              "mod_max_rank": 3,
                              "id": "54a74454e779892d5e515664",
                              "url_name": "gilded_truth",
                              "icon": "items/images/en/gilded_truth.4f864f82b65bf77a28c01419c6cbfce1.png",
                              "thumb": "items/images/en/thumbs/gilded_truth.4f864f82b65bf77a28c01419c6cbfce1.128x128.png",
                              "sub_icon": null,
                              "tags": [
                                  "syndicate",
                                  "burston_prime",
                                  "mod",
                                  "rare",
                                  "primary",
                                  "prime"
                              ],
                              "icon_format": "port",
                              "en": {
                                  "item_name": "Gilded Truth"
                              },
                              "ru": {
                                  "item_name": "Позолоченная Правда"
                              },
                              "ko": {
                                  "item_name": "길디드 트루스"
                              },
                              "fr": {
                                  "item_name": "Vérité Dorée"
                              },
                              "sv": {
                                  "item_name": "Gilded Truth"
                              },
                              "de": {
                                  "item_name": "Vergoldete Wahrheit"
                              },
                              "zh-hant": {
                                  "item_name": "鍍金真相"
                              },
                              "zh-hans": {
                                  "item_name": "镀金真相"
                              },
                              "pt": {
                                  "item_name": "Gilded Truth"
                              },
                              "es": {
                                  "item_name": "Verdad Dorada"
                              },
                              "pl": {
                                  "item_name": "Pozłacana Prawda"
                              },
                              "cs": {
                                  "item_name": "Gilded Truth"
                              },
                              "uk": {
                                  "item_name": "Позолочена Правда"
                              },
                              "it": {
                                  "item_name": "Gilded Truth"
                              }
                          },
                          "platinum": 14,
                          "quantity": 1,
                          "visible": true,
                          "creation_date": "2025-01-13T17:15:28.253+00:00",
                          "last_update": "2025-01-13T17:15:28.253+00:00",
                          "mod_rank": 0,
                          "order_type": "sell",
                          "region": "en",
                          "platform": "pc"
                      },
                      {
                          "id": "67854a3e3ba9d8000958f065",
                          "item": {
                              "mod_max_rank": 3,
                              "id": "54a74454e779892d5e515645",
                              "url_name": "blade_of_truth",
                              "icon": "items/images/en/blade_of_truth.53d68caa8f7ae06642b2ed1fd8f3b6cd.png",
                              "thumb": "items/images/en/thumbs/blade_of_truth.53d68caa8f7ae06642b2ed1fd8f3b6cd.128x128.png",
                              "sub_icon": null,
                              "tags": [
                                  "syndicate",
                                  "mod",
                                  "melee",
                                  "rare",
                                  "jaw_sword"
                              ],
                              "icon_format": "port",
                              "en": {
                                  "item_name": "Blade Of Truth"
                              },
                              "ru": {
                                  "item_name": "Клинок Правды"
                              },
                              "ko": {
                                  "item_name": "블레이드 오브 트루스"
                              },
                              "fr": {
                                  "item_name": "Lames De La Vérité"
                              },
                              "sv": {
                                  "item_name": "Blade Of Truth"
                              },
                              "de": {
                                  "item_name": "Klinge Der Wahrheit"
                              },
                              "zh-hant": {
                                  "item_name": "真相之刃"
                              },
                              "zh-hans": {
                                  "item_name": "真相之刃"
                              },
                              "pt": {
                                  "item_name": "Blade Of Truth"
                              },
                              "es": {
                                  "item_name": "Hoja De La Verdad"
                              },
                              "pl": {
                                  "item_name": "Ostrze Prawdy"
                              },
                              "cs": {
                                  "item_name": "Blade Of Truth"
                              },
                              "uk": {
                                  "item_name": "Лезо Правди"
                              },
                              "it": {
                                  "item_name": "Blade Of Truth"
                              }
                          },
                          "platinum": 17,
                          "quantity": 1,
                          "visible": true,
                          "creation_date": "2025-01-13T17:15:42.418+00:00",
                          "last_update": "2025-01-13T17:15:42.418+00:00",
                          "mod_rank": 0,
                          "order_type": "sell",
                          "region": "en",
                          "platform": "pc"
                      },
                      {
                          "id": "67854b7a093d4c0008f12181",
                          "item": {
                              "mod_max_rank": 3,
                              "id": "54a74454e779892d5e5155ee",
                              "url_name": "entropy_flight",
                              "icon": "items/images/en/entropy_flight.d0aac5dc51491213cff3e4ff49c9acff.png",
                              "thumb": "items/images/en/thumbs/entropy_flight.d0aac5dc51491213cff3e4ff49c9acff.128x128.png",
                              "sub_icon": null,
                              "tags": [
                                  "syndicate",
                                  "mod",
                                  "melee",
                                  "rare",
                                  "kestrel"
                              ],
                              "icon_format": "port",
                              "en": {
                                  "item_name": "Entropy Flight"
                              },
                              "ru": {
                                  "item_name": "Полёт Энтропии"
                              },
                              "ko": {
                                  "item_name": "엔트로피 플라이트"
                              },
                              "fr": {
                                  "item_name": "Vol Entropique"
                              },
                              "sv": {
                                  "item_name": "Entropy Flight"
                              },
                              "de": {
                                  "item_name": "Entropie-Flug"
                              },
                              "zh-hant": {
                                  "item_name": "飛逝熵數"
                              },
                              "zh-hans": {
                                  "item_name": "飞逝熵数"
                              },
                              "pt": {
                                  "item_name": "Entropy Flight"
                              },
                              "es": {
                                  "item_name": "Trayectoria De Entropía"
                              },
                              "pl": {
                                  "item_name": "Lot Entropii"
                              },
                              "cs": {
                                  "item_name": "Entropy Flight"
                              },
                              "uk": {
                                  "item_name": "Політ Ентропії"
                              },
                              "it": {
                                  "item_name": "Entropy Flight"
                              }
                          },
                          "platinum": 14,
                          "quantity": 1,
                          "visible": true,
                          "creation_date": "2025-01-13T17:20:58.003+00:00",
                          "last_update": "2025-01-13T17:20:58.003+00:00",
                          "mod_rank": 0,
                          "order_type": "sell",
                          "region": "en",
                          "platform": "pc"
                      }
                  ],
                  "buy_orders": []
              }
          }
          """

        conn
        |> Conn.put_resp_header(
          "Set-Cookie",
          "JWT=old_cookie; Domain=.warframe.market; Expires=Tue, 21-Mar-2023 15:16:03 GMT; Secure; HttpOnly; Path=/; SameSite=Lax"
        )
        |> Conn.put_resp_header("content-type", "application/json")
        |> Conn.resp(200, body)
      end)

      Bypass.expect_once(bypass, "DELETE", "/v1/profile/orders/678549e7093d4c0008f12149", fn conn ->
        body =
          """
          {
            "payload": {
                "order_id": "678549e7093d4c0008f12149"
            }
          }
          """

        conn
        |> Conn.put_resp_header(
          "Set-Cookie",
          "JWT=old_cookie; Domain=.warframe.market; Expires=Tue, 21-Mar-2023 15:16:03 GMT; Secure; HttpOnly; Path=/; SameSite=Lax"
        )
        |> Conn.put_resp_header("content-type", "application/json")
        |> Conn.resp(200, body)
      end)

      Bypass.expect_once(bypass, "DELETE", "/v1/profile/orders/67854a1371aa440007eb3de9", fn conn ->
        body =
          """
          {
            "payload": {
                "order_id": "67854a1371aa440007eb3de9"
            }
          }
          """

        conn
        |> Conn.put_resp_header(
          "Set-Cookie",
          "JWT=old_cookie; Domain=.warframe.market; Expires=Tue, 21-Mar-2023 15:16:03 GMT; Secure; HttpOnly; Path=/; SameSite=Lax"
        )
        |> Conn.put_resp_header("content-type", "application/json")
        |> Conn.resp(200, body)
      end)

      Bypass.expect_once(bypass, "DELETE", "/v1/profile/orders/67854a303ba9d80007de3e5d", fn conn ->
        body =
          """
          {
            "payload": {
                "order_id": "67854a303ba9d80007de3e5d"
            }
          }
          """

        conn
        |> Conn.put_resp_header(
          "Set-Cookie",
          "JWT=old_cookie; Domain=.warframe.market; Expires=Tue, 21-Mar-2023 15:16:03 GMT; Secure; HttpOnly; Path=/; SameSite=Lax"
        )
        |> Conn.put_resp_header("content-type", "application/json")
        |> Conn.resp(200, body)
      end)

      Bypass.expect_once(bypass, "DELETE", "/v1/profile/orders/67854a3e3ba9d8000958f065", fn conn ->
        body =
          """
          {
            "payload": {
                "order_id": "67854a3e3ba9d8000958f065"
            }
          }
          """

        conn
        |> Conn.put_resp_header(
          "Set-Cookie",
          "JWT=old_cookie; Domain=.warframe.market; Expires=Tue, 21-Mar-2023 15:16:03 GMT; Secure; HttpOnly; Path=/; SameSite=Lax"
        )
        |> Conn.put_resp_header("content-type", "application/json")
        |> Conn.resp(200, body)
      end)

      Bypass.expect_once(bypass, "DELETE", "/v1/profile/orders/67854b7a093d4c0008f12181", fn conn ->
        body =
          """
          {
            "payload": {
                "order_id": "67854b7a093d4c0008f12181"
            }
          }
          """

        conn
        |> Conn.put_resp_header(
          "Set-Cookie",
          "JWT=old_cookie; Domain=.warframe.market; Expires=Tue, 21-Mar-2023 15:16:03 GMT; Secure; HttpOnly; Path=/; SameSite=Lax"
        )
        |> Conn.put_resp_header("content-type", "application/json")
        |> Conn.resp(200, body)
      end)

      :ok = Manager.deactivate([:steel_meridian, :arbiters_of_hexis])
      assert_receive({:deactivate, {:ok, :get_user_orders}}, @timeout)
      assert_receive({:deactivate, {:ok, :deleting_orders}}, @timeout)

      assert_receive(
        {:deactivate, {:ok, {:order_deleted, "Scattered Justice", 1, 5}}},
        @timeout
      )

      assert_receive(
        {:deactivate, {:ok, {:order_deleted, "Justice Blades", 2, 5}}},
        @timeout
      )

      assert_receive(
        {:deactivate, {:ok, {:order_deleted, "Gilded Truth", 3, 5}}},
        @timeout
      )

      assert_receive(
        {:deactivate, {:ok, {:order_deleted, "Blade of Truth", 4, 5}}},
        @timeout
      )

      assert_receive(
        {:deactivate, {:ok, {:order_deleted, "Entropy Flight", 5, 5}}},
        @timeout
      )

      assert_receive({:deactivate, {:ok, :reactivating_remaining_syndicates}}, @timeout)

      Bypass.expect(bypass, "GET", "/v1/profile/fl4m3/orders", fn conn ->
        body =
          """
          {
              "payload": {
                  "sell_orders": [],
                  "buy_orders": []
              }
          }
          """

        conn
        |> Conn.put_resp_header(
          "Set-Cookie",
          "JWT=old_cookie; Domain=.warframe.market; Expires=Tue, 21-Mar-2023 15:16:03 GMT; Secure; HttpOnly; Path=/; SameSite=Lax"
        )
        |> Conn.put_resp_header("content-type", "application/json")
        |> Conn.resp(200, body)
      end)

      assert_receive({:activate, {:ok, :get_user_orders}}, @timeout)

      Bypass.expect_once(bypass, "GET", "/v1/items/entropy_flight/orders", fn conn ->
        body = """
        {
            "payload": {
                "orders": [
                    {
                        "creation_date": "2017-10-26T05:00:46.000+00:00",
                        "visible": true,
                        "quantity": 1,
                        "user": {
                            "reputation": 15,
                            "locale": "en",
                            "avatar": "user/avatar/572d5db2d3ffb6178005ddd1.png?19b6ed0dc1055d18517b483cd088317c",
                            "ingame_name": "Stkestrel",
                            "last_seen": "2025-01-14T14:03:04.332+00:00",
                            "crossplay": false,
                            "platform": "pc",
                            "id": "572d5db2d3ffb6178005ddd1",
                            "region": "en",
                            "status": "ingame"
                        },
                        "last_update": "2024-12-30T17:14:59.000+00:00",
                        "platinum": 14,
                        "order_type": "sell",
                        "id": "59f16bfe0f31391483e31d8b",
                        "mod_rank": 0,
                        "region": "en"
                    },
                    {
                        "order_type": "sell",
                        "platinum": 15,
                        "quantity": 1,
                        "user": {
                            "reputation": 31,
                            "locale": "en",
                            "avatar": "user/avatar/58a3561ed3ffb61563095fd1.png?ab346e5060556181f08a5562804fb12c",
                            "ingame_name": "ANDRESMABG",
                            "last_seen": "2025-01-14T01:39:46.167+00:00",
                            "crossplay": false,
                            "platform": "pc",
                            "id": "58a3561ed3ffb61563095fd1",
                            "region": "en",
                            "status": "ingame"
                        },
                        "creation_date": "2019-04-29T21:23:36.000+00:00",
                        "last_update": "2019-04-29T21:23:36.000+00:00",
                        "visible": true,
                        "id": "5cc76b5824e70a12a6bfeb4e",
                        "mod_rank": 0,
                        "region": "en"
                    },
                    {
                        "quantity": 1,
                        "platinum": 100,
                        "order_type": "sell",
                        "user": {
                            "reputation": 1028,
                            "locale": "en",
                            "avatar": "user/avatar/5686d3e3cbfa8f12f73672f1.png?4c3f058d716e3513efb955759d2049de",
                            "ingame_name": "-BM-SniperKitten",
                            "last_seen": "2025-01-14T12:34:48.064+00:00",
                            "crossplay": false,
                            "platform": "pc",
                            "id": "5686d3e3cbfa8f12f73672f1",
                            "region": "en",
                            "status": "ingame"
                        },
                        "creation_date": "2019-09-04T12:53:21.000+00:00",
                        "last_update": "2024-03-18T06:44:35.000+00:00",
                        "visible": true,
                        "id": "5d6fb3c135f886032cc33764",
                        "mod_rank": 3,
                        "region": "en"
                    }
                ]
            }
        }
        """

        conn
        |> Plug.Conn.put_resp_header(
          "Set-Cookie",
          "JWT=old_cookie; Domain=.warframe.market; Expires=Tue, 21-Mar-2023 15:16:03 GMT; Secure; HttpOnly; Path=/; SameSite=Lax"
        )
        |> Conn.put_resp_header("content-type", "application/json")
        |> Plug.Conn.resp(200, body)
      end)

      assert_receive({:activate, {:ok, :calculating_item_prices}}, @timeout)
      assert_receive({:activate, {:ok, {:price_calculated, "Entropy Flight", 14, 1, 1}}}, @timeout)
      assert_receive({:activate, {:ok, :placing_orders}}, @timeout)

      Bypass.expect_once(bypass, "POST", "/v1/profile/orders", fn conn ->
        {:ok, actual_request_body, _req_conn} = Plug.Conn.read_body(conn)

        expected_request_body =
          "{\"item_id\":\"54a74454e779892d5e5155ee\",\"order_type\":\"sell\",\"platinum\":14,\"quantity\":1,\"mod_rank\":0}"

        if actual_request_body != expected_request_body do
          throw("Unknown POST request received. Expected:\n#{expected_request_body}\nBut got:\n#{actual_request_body}")
        end

        response =
          """
          {
            "payload": {
              "order": {
                "visible": true,
                "item": {
                  "id": "54a74454e779892d5e5155ee",
                  "mod_max_rank": 3,
                  "url_name": "entropy_flight",
                  "thumb": "items/images/en/thumbs/entropy_flight.d0aac5dc51491213cff3e4ff49c9acff.128x128.png",
                  "sub_icon": null,
                  "icon_format": "port",
                  "icon": "items/images/en/entropy_flight.d0aac5dc51491213cff3e4ff49c9acff.png",
                  "tags": [
                    "syndicate",
                    "mod",
                    "melee",
                    "rare",
                    "kestrel"
                  ],
                  "en": {
                    "item_name": "Entropy Flight"
                  },
                  "ru": {
                    "item_name": "Полёт Энтропии"
                  },
                  "ko": {
                    "item_name": "엔트로피 플라이트"
                  },
                  "fr": {
                    "item_name": "Vol Entropique"
                  },
                  "sv": {
                    "item_name": "Entropy Flight"
                  },
                  "de": {
                    "item_name": "Entropie-Flug"
                  },
                  "zh-hant": {
                    "item_name": "飛逝熵數"
                  },
                  "zh-hans": {
                    "item_name": "飞逝熵数"
                  },
                  "pt": {
                    "item_name": "Entropy Flight"
                  },
                  "es": {
                    "item_name": "Trayectoria De Entropía"
                  },
                  "pl": {
                    "item_name": "Lot Entropii"
                  },
                  "cs": {
                    "item_name": "Entropy Flight"
                  },
                  "uk": {
                    "item_name": "Політ Ентропії"
                  },
                  "it": {
                    "item_name": "Entropy Flight"
                  }
                },
                "order_type": "sell",
                "id": "6787e48f7d979600318ac68d",
                "region": "en",
                "platinum": 14,
                "mod_rank": 0,
                "quantity": 1,
                "creation_date": "2025-01-15T16:38:39.749+00:00",
                "last_update": "2025-01-15T16:38:39.749+00:00",
                "platform": "pc"
              }
            }
          }
          """

        conn
        |> Plug.Conn.put_resp_header(
          "Set-Cookie",
          "JWT=old_cookie; Domain=.warframe.market; Expires=Tue, 21-Mar-2023 15:16:03 GMT; Secure; HttpOnly; Path=/; SameSite=Lax"
        )
        |> Conn.put_resp_header("content-type", "application/json")
        |> Plug.Conn.resp(200, response)
      end)

      assert_receive({:activate, {:ok, {:order_placed, "Entropy Flight", 1, 1}}}, @timeout)
      assert_receive({:activate, {:ok, :done}}, @timeout)

      assert Manager.active_syndicates() == {:ok, %{cephalon_suda: :lowest_minus_one}}
    end
  end

  describe "login/2" do
    setup do
      create_setup_file()
      on_exit(&reset_setup_file/0)

      bypass = Bypass.open(port: 8082)
      credentials = Credentials.new("an_email", "a_password")
      authorization = Authorization.new(%{"cookie" => "a_cookie", "token" => "a_token"})
      user = User.new(%{"ingame_name" => "fl4m3", "patreon?" => false})

      %{
        credentials: credentials,
        authorization: authorization,
        user: user,
        bypass: bypass
      }
    end

    test "logs in user correctly when no login data is saved", %{bypass: bypass, credentials: credentials} do
      reset_setup_file()

      Bypass.expect_once(bypass, "GET", "/auth/signin", fn conn ->
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

      Bypass.expect_once(bypass, "POST", "/v1/auth/signin", fn conn ->
        body =
          "{\"payload\": {\"user\": {\"has_mail\": true, \"written_reviews\": 0, \"region\": \"en\", \"banned\": false, \"anonymous\": false, \"role\": \"user\", \"reputation\": 84, \"ingame_name\": \"Fl4m3Ph03n1x\", \"platform\": \"pc\", \"unread_messages\": 0, \"background\": null, \"check_code\": \"66BAPR88DLLZ\", \"avatar\": \"user/avatar/584d425cd3ffb630c3f9df42.png?0a8ad917dc66b85aa69520d70a31dafb\", \"verification\": true, \"linked_accounts\": {\"steam_profile\": true, \"patreon_profile\": false, \"xbox_profile\": false, \"discord_profile\": false, \"github_profile\": false}, \"id\": \"584d425cd3ffb630c3f9df42\", \"locale\": \"en\"}}}"

        conn
        |> Plug.Conn.put_resp_header(
          "Set-Cookie",
          "JWT=new_cookie; Domain=.warframe.market; Expires=Tue, 21-Mar-2023 14:41:06 GMT; Secure; HttpOnly; Path=/; SameSite=Lax"
        )
        |> Plug.Conn.resp(200, body)
      end)

      _manager_pid = start_supervised(ManagerSupervisor)
      :ok = Manager.login(credentials, false)

      assert_receive({:login, {:ok, %User{patreon?: false, ingame_name: "Fl4m3Ph03n1x"}}}, @timeout)
    end

    test "logs in user correctly when there is previous login data", %{credentials: credentials} do
      _manager_pid = start_supervised(ManagerSupervisor)
      :ok = Manager.login(credentials, false)

      assert_receive({:login, {:ok, %User{patreon?: false, ingame_name: "fl4m3"}}}, @timeout)
    end
  end

  describe "recover_login/0" do
    setup do
      create_setup_file()
      on_exit(&reset_setup_file/0)

      credentials = Credentials.new("an_email", "a_password")
      authorization = Authorization.new(%{"cookie" => "a_cookie", "token" => "a_token"})
      user = User.new(%{"ingame_name" => "fl4m3", "patreon?" => false})

      %{
        credentials: credentials,
        authorization: authorization,
        user: user
      }
    end

    test "returns user when successful" do
      _manager_pid = start_supervised(ManagerSupervisor)

      assert Manager.recover_login() == {:ok, %User{patreon?: false, ingame_name: "fl4m3"}}
    end

    test "returns nil if no login session is found" do
      reset_setup_file()

      _manager_pid = start_supervised(ManagerSupervisor)

      assert Manager.recover_login() == {:ok, nil}
    end
  end

  describe "logout/0" do
    setup do
      create_setup_file()
      on_exit(&reset_setup_file/0)

      credentials = Credentials.new("an_email", "a_password")
      user = User.new(%{"ingame_name" => "fl4m3", "patreon?" => false})

      %{
        credentials: credentials,
        user: user
      }
    end

    test "returns OK if session is deleted from disk and memory", %{credentials: credentials, user: user} do
      _manager_pid = start_supervised(ManagerSupervisor)

      assert Manager.login(credentials, true) == :ok
      assert_receive({:login, {:ok, ^user}}, @timeout)

      assert Manager.recover_login() == {:ok, user}
      assert Manager.logout() == :ok
      assert Manager.recover_login() == {:ok, nil}
    end
  end

  describe "syndicates/0" do
    test "returns known syndicates" do
      _manager_pid = start_supervised(ManagerSupervisor)

      {:ok, syndicates} = Manager.syndicates()
      syndicate_ids = Enum.map(syndicates, fn syndicate -> syndicate.id end)

      assert syndicate_ids == [
               :red_veil,
               :new_loka,
               :perrin_sequence,
               :steel_meridian,
               :arbiters_of_hexis,
               :cephalon_suda,
               :cephalon_simaris,
               :arbitrations
             ]
    end
  end

  describe "active_syndicates" do
    setup do
      create_watch_list_file(%{cephalon_suda: :lowest_minus_one, cephalon_simaris: :equal_to_lowest})
      on_exit(&reset_watch_list_file/0)
    end

    test "returns currently active syndicates with their strategies" do
      _manager_pid = start_supervised(ManagerSupervisor)

      assert Manager.active_syndicates() ==
               {:ok, %{cephalon_suda: :lowest_minus_one, cephalon_simaris: :equal_to_lowest}}
    end
  end

  describe "strategies" do
    test "returns the strategies" do
      # Arrange
      _manager_pid = start_supervised(ManagerSupervisor)

      expected_strategies = [
        %Strategy{
          description: "Gets the 3 lowest prices for the given item and calculates the average.",
          id: :top_three_average,
          name: "Top 3 Average"
        },
        %Strategy{
          description: "Gets the 5 lowest prices for the given item and calculates the average.",
          id: :top_five_average,
          name: "Top 5 Average"
        },
        %Strategy{
          description: "Gets the lowest price for the given item and beats it by 1.",
          id: :lowest_minus_one,
          name: "Lowest minus one"
        },
        %Strategy{
          description: "Gets the lowest price for the given item and uses it.",
          id: :equal_to_lowest,
          name: "Equal to lowest"
        }
      ]

      # Act and Assert
      assert Manager.strategies() == {:ok, expected_strategies}
    end
  end
end
