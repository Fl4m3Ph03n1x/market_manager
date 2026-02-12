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
          ingame_name: "Fl4m3",
          slug: "fl4m3",
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

      _manager_pid = start_supervised(ManagerSupervisor)
      :ok = Manager.login(credentials, false)

      assert_receive({:login, {:ok, %User{patreon?: false, ingame_name: "Fl4m3", slug: "fl4m3"}}}, @timeout)

      %{
        bypass: bypass
      }
    end

    test "activates single syndicate with strategy when user has no previous orders", %{bypass: bypass} do
      # get current user orders
      Bypass.expect_once(bypass, "GET", "/v2/orders/user/fl4m3", fn conn ->
        body =
          """
          {
            "apiVersion": "0.22.7",
            "data": [],
            "error": null
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
      Bypass.expect_once(bypass, "GET", "/v2/orders/item/scattered_justice", fn conn ->
        body =
          """
          {
            "apiVersion": "0.22.7",
            "data": [
              {
                "id": "57ddaebfd3ffb614b4c30a26",
                "type": "sell",
                "platinum": 8,
                "quantity": 1,
                "perTrade": 1,
                "rank": 0,
                "visible": true,
                "createdAt": "2016-09-17T20:59:43Z",
                "updatedAt": "2025-05-26T16:44:40Z",
                "itemId": "54a74454e779892d5e5155f5",
                "user": {
                  "id": "55e4a699e7798970d227aee2",
                  "ingameName": "AdeptFly",
                  "slug": "adeptfly",
                  "avatar": "user/avatar/55e4a699e7798970d227aee2.png?8508d4b5c7e15fe6eb06f5c658e1df19",
                  "reputation": 71,
                  "platform": "pc",
                  "crossplay": true,
                  "locale": "en",
                  "status": "ingame",
                  "activity": {
                    "type": "UNKNOWN",
                    "details": "unknown"
                  },
                  "lastSeen": "2026-02-11T03:45:47Z"
                }
              },
              {
                "id": "592bc664d3ffb66d942ad31d",
                "type": "sell",
                "platinum": 34,
                "quantity": 1,
                "perTrade": 1,
                "rank": 3,
                "visible": true,
                "createdAt": "2017-05-29T06:57:40Z",
                "updatedAt": "2026-02-02T21:35:51Z",
                "itemId": "54a74454e779892d5e5155f5",
                "user": {
                  "id": "573c35c80f313929c8886c79",
                  "ingameName": "-Gh0stMan-",
                  "slug": "gh0stman",
                  "reputation": 19,
                  "platform": "pc",
                  "crossplay": true,
                  "locale": "en",
                  "status": "ingame",
                  "activity": {
                    "type": "UNKNOWN",
                    "details": "unknown"
                  },
                  "lastSeen": "2026-02-10T21:31:15Z"
                }
              },
              {
                "id": "59c07a790f31396e83ed709b",
                "type": "sell",
                "platinum": 18,
                "quantity": 992,
                "perTrade": 1,
                "rank": 0,
                "visible": true,
                "createdAt": "2017-09-19T02:01:29Z",
                "updatedAt": "2025-06-21T04:03:42Z",
                "itemId": "54a74454e779892d5e5155f5",
                "user": {
                  "id": "5678a156cbfa8f02c9b814c3",
                  "ingameName": "Ealirinineomh",
                  "slug": "ealirinineomh",
                  "avatar": "user/avatar/5678a156cbfa8f02c9b814c3.png?0d832d1017240078ecf4bdeb0d08a101",
                  "reputation": 2124,
                  "platform": "pc",
                  "crossplay": true,
                  "locale": "en",
                  "status": "ingame",
                  "activity": {
                    "type": "UNKNOWN",
                    "details": "unknown"
                  },
                  "lastSeen": "2026-02-11T07:21:03Z"
                }
              }
            ],
            "error": null
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
      Bypass.expect_once(bypass, "GET", "/v2/orders/item/justice_blades", fn conn ->
        body =
          """
          {
            "apiVersion": "0.22.7",
            "data": [
              {
                "id": "57ddaed40f313914d250cd87",
                "type": "sell",
                "platinum": 8,
                "quantity": 1,
                "perTrade": 1,
                "rank": 0,
                "visible": true,
                "createdAt": "2016-09-17T21:00:04Z",
                "updatedAt": "2025-05-26T16:45:24Z",
                "itemId": "54a74455e779892d5e5156b9",
                "user": {
                  "id": "55e4a699e7798970d227aee2",
                  "ingameName": "AdeptFly",
                  "slug": "adeptfly",
                  "avatar": "user/avatar/55e4a699e7798970d227aee2.png?8508d4b5c7e15fe6eb06f5c658e1df19",
                  "reputation": 71,
                  "platform": "pc",
                  "crossplay": true,
                  "locale": "en",
                  "status": "online",
                  "activity": {
                    "type": "UNKNOWN",
                    "details": "unknown"
                  },
                  "lastSeen": "2026-02-11T03:45:47Z"
                }
              },
              {
                "id": "592bc66fd3ffb66d8ce464e6",
                "type": "sell",
                "platinum": 34,
                "quantity": 1,
                "perTrade": 1,
                "rank": 3,
                "visible": true,
                "createdAt": "2017-05-29T06:57:51Z",
                "updatedAt": "2026-02-02T21:35:34Z",
                "itemId": "54a74455e779892d5e5156b9",
                "user": {
                  "id": "573c35c80f313929c8886c79",
                  "ingameName": "-Gh0stMan-",
                  "slug": "gh0stman",
                  "reputation": 19,
                  "platform": "pc",
                  "crossplay": true,
                  "locale": "en",
                  "status": "ingame",
                  "activity": {
                    "type": "UNKNOWN",
                    "details": "unknown"
                  },
                  "lastSeen": "2026-02-10T21:31:15Z"
                }
              },
              {
                "id": "598f76440f313951e3167944",
                "type": "sell",
                "platinum": 18,
                "quantity": 999,
                "perTrade": 1,
                "rank": 0,
                "visible": true,
                "createdAt": "2017-08-12T21:42:28Z",
                "updatedAt": "2025-06-21T04:03:38Z",
                "itemId": "54a74455e779892d5e5156b9",
                "user": {
                  "id": "5678a156cbfa8f02c9b814c3",
                  "ingameName": "Ealirinineomh",
                  "slug": "ealirinineomh",
                  "avatar": "user/avatar/5678a156cbfa8f02c9b814c3.png?0d832d1017240078ecf4bdeb0d08a101",
                  "reputation": 2124,
                  "platform": "pc",
                  "crossplay": true,
                  "locale": "en",
                  "status": "offline",
                  "activity": {
                    "type": "UNKNOWN",
                    "details": "unknown"
                  },
                  "lastSeen": "2026-02-11T07:21:03Z"
                }
              }
            ],
            "error": null
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
      Bypass.expect(bypass, "POST", "/v2/order", fn conn ->
        {:ok, req_body, _req_conn} = Plug.Conn.read_body(conn)
        decoded_request = Jason.decode!(req_body)

        response_body =
          case Map.get(decoded_request, "itemId") do
            # Scattered Justice
            "54a74454e779892d5e5155f5" ->
              """
              {
                "apiVersion": "0.22.7",
                "data": {
                  "id": "698c92e86a51e1b3b0f6a143",
                  "type": "sell",
                  "platinum": 15,
                  "quantity": 1,
                  "perTrade": 1,
                  "rank": 0,
                  "visible": true,
                  "createdAt": "2026-02-11T14:32:08Z",
                  "updatedAt": "2026-02-11T14:32:08Z",
                  "itemId": "54a74454e779892d5e5155f5"
                },
                "error": null
              }
              """

            # Justice Blades
            "54a74455e779892d5e5156b9" ->
              """
              {
                "apiVersion": "0.22.7",
                "data": {
                  "id": "698c928ba7a2008a73b0059c",
                  "type": "sell",
                  "platinum": 15,
                  "quantity": 1,
                  "perTrade": 1,
                  "rank": 0,
                  "visible": true,
                  "createdAt": "2026-02-11T14:30:35Z",
                  "updatedAt": "2026-02-11T14:30:35Z",
                  "itemId": "54a74455e779892d5e5156b9"
                },
                "error": null
              }
              """

            _ ->
              throw("malformed request: #{req_body}")
          end

        conn
        |> Plug.Conn.put_resp_header(
          "Set-Cookie",
          "JWT=old_cookie; Domain=.warframe.market; Expires=Tue, 21-Mar-2023 15:16:03 GMT; Secure; HttpOnly; Path=/; SameSite=Lax"
        )
        |> Conn.put_resp_header("content-type", "application/json")
        |> Plug.Conn.resp(200, response_body)
      end)

      :ok = Manager.activate(%{steel_meridian: :top_three_average})

      assert_receive({:activate, {:ok, :get_user_orders}}, @timeout)
      assert_receive({:activate, {:ok, :calculating_item_prices}}, @timeout)
      assert_receive({:activate, {:ok, {:price_calculated, "Scattered Justice", 20, 1, 2}}}, @timeout)
      assert_receive({:activate, {:ok, {:price_calculated, "Justice Blades", 34, 2, 2}}}, @timeout)
      assert_receive({:activate, {:ok, :placing_orders}}, @timeout)
      assert_receive({:activate, {:ok, {:order_placed, "Scattered Justice", 1, 2}}}, @timeout)
      assert_receive({:activate, {:ok, {:order_placed, "Justice Blades", 2, 2}}}, @timeout)
      assert_receive({:activate, {:ok, :done}}, @timeout)

      assert Manager.active_syndicates() == {:ok, %{steel_meridian: :top_three_average}}
    end

    test "activates multiple syndicates with the given strategies when user has previous orders", %{bypass: bypass} do
      # get current user orders
      Bypass.expect(bypass, "GET", "/v2/orders/user/fl4m3", fn conn ->
        # "itemId": "54e644ffe779897594fa68d2" -> Abating Link
        # "itemId": "5ecd08d704d55c0806f85348" -> Abundant Mutation
        body =
          """
          {
            "apiVersion": "0.22.7",
            "data": [
              {
                "id": "698daf1a6a51e1b3b0f87014",
                "type": "sell",
                "platinum": 15,
                "quantity": 1,
                "perTrade": 1,
                "rank": 0,
                "visible": true,
                "createdAt": "2026-02-12T10:44:42Z",
                "updatedAt": "2026-02-12T10:44:42Z",
                "itemId": "54e644ffe779897594fa68d2"
              },
              {
                "id": "698daf27a7a2008a73b1c164",
                "type": "sell",
                "platinum": 17,
                "quantity": 1,
                "perTrade": 1,
                "rank": 0,
                "visible": true,
                "createdAt": "2026-02-12T10:44:55Z",
                "updatedAt": "2026-02-12T10:44:55Z",
                "itemId": "5ecd08d704d55c0806f85348"
              }
            ],
            "error": null
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
      Bypass.expect_once(bypass, "GET", "/v2/orders/item/scattered_justice", fn conn ->
        body =
          """
          {
            "apiVersion": "0.22.7",
            "data": [
              {
                "id": "57ddaebfd3ffb614b4c30a26",
                "type": "sell",
                "platinum": 8,
                "quantity": 1,
                "perTrade": 1,
                "rank": 0,
                "visible": true,
                "createdAt": "2016-09-17T20:59:43Z",
                "updatedAt": "2025-05-26T16:44:40Z",
                "itemId": "54a74454e779892d5e5155f5",
                "user": {
                  "id": "55e4a699e7798970d227aee2",
                  "ingameName": "AdeptFly",
                  "slug": "adeptfly",
                  "avatar": "user/avatar/55e4a699e7798970d227aee2.png?8508d4b5c7e15fe6eb06f5c658e1df19",
                  "reputation": 71,
                  "platform": "pc",
                  "crossplay": true,
                  "locale": "en",
                  "status": "ingame",
                  "activity": {
                    "type": "UNKNOWN",
                    "details": "unknown"
                  },
                  "lastSeen": "2026-02-11T03:45:47Z"
                }
              },
              {
                "id": "592bc664d3ffb66d942ad31d",
                "type": "sell",
                "platinum": 34,
                "quantity": 1,
                "perTrade": 1,
                "rank": 3,
                "visible": true,
                "createdAt": "2017-05-29T06:57:40Z",
                "updatedAt": "2026-02-02T21:35:51Z",
                "itemId": "54a74454e779892d5e5155f5",
                "user": {
                  "id": "573c35c80f313929c8886c79",
                  "ingameName": "-Gh0stMan-",
                  "slug": "gh0stman",
                  "reputation": 19,
                  "platform": "pc",
                  "crossplay": true,
                  "locale": "en",
                  "status": "ingame",
                  "activity": {
                    "type": "UNKNOWN",
                    "details": "unknown"
                  },
                  "lastSeen": "2026-02-10T21:31:15Z"
                }
              },
              {
                "id": "59c07a790f31396e83ed709b",
                "type": "sell",
                "platinum": 18,
                "quantity": 992,
                "perTrade": 1,
                "rank": 0,
                "visible": true,
                "createdAt": "2017-09-19T02:01:29Z",
                "updatedAt": "2025-06-21T04:03:42Z",
                "itemId": "54a74454e779892d5e5155f5",
                "user": {
                  "id": "5678a156cbfa8f02c9b814c3",
                  "ingameName": "Ealirinineomh",
                  "slug": "ealirinineomh",
                  "avatar": "user/avatar/5678a156cbfa8f02c9b814c3.png?0d832d1017240078ecf4bdeb0d08a101",
                  "reputation": 2124,
                  "platform": "pc",
                  "crossplay": true,
                  "locale": "en",
                  "status": "ingame",
                  "activity": {
                    "type": "UNKNOWN",
                    "details": "unknown"
                  },
                  "lastSeen": "2026-02-11T07:21:03Z"
                }
              }
            ],
            "error": null
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
      Bypass.expect_once(bypass, "GET", "/v2/orders/item/justice_blades", fn conn ->
        body =
          """
          {
            "apiVersion": "0.22.7",
            "data": [
              {
                "id": "57ddaed40f313914d250cd87",
                "type": "sell",
                "platinum": 8,
                "quantity": 1,
                "perTrade": 1,
                "rank": 0,
                "visible": true,
                "createdAt": "2016-09-17T21:00:04Z",
                "updatedAt": "2025-05-26T16:45:24Z",
                "itemId": "54a74455e779892d5e5156b9",
                "user": {
                  "id": "55e4a699e7798970d227aee2",
                  "ingameName": "AdeptFly",
                  "slug": "adeptfly",
                  "avatar": "user/avatar/55e4a699e7798970d227aee2.png?8508d4b5c7e15fe6eb06f5c658e1df19",
                  "reputation": 70,
                  "platform": "pc",
                  "crossplay": true,
                  "locale": "en",
                  "status": "ingame",
                  "activity": {
                    "type": "UNKNOWN",
                    "details": "unknown"
                  },
                  "lastSeen": "2026-02-09T03:52:23Z"
                }
              },
              {
                "id": "592bc66fd3ffb66d8ce464e6",
                "type": "sell",
                "platinum": 34,
                "quantity": 1,
                "perTrade": 1,
                "rank": 3,
                "visible": true,
                "createdAt": "2017-05-29T06:57:51Z",
                "updatedAt": "2026-02-02T21:35:34Z",
                "itemId": "54a74455e779892d5e5156b9",
                "user": {
                  "id": "573c35c80f313929c8886c79",
                  "ingameName": "-Gh0stMan-",
                  "slug": "gh0stman",
                  "reputation": 19,
                  "platform": "pc",
                  "crossplay": true,
                  "locale": "en",
                  "status": "ingame",
                  "activity": {
                    "type": "UNKNOWN",
                    "details": "unknown"
                  },
                  "lastSeen": "2026-02-09T15:19:38Z"
                }
              },
              {
                "id": "598f76440f313951e3167944",
                "type": "sell",
                "platinum": 18,
                "quantity": 999,
                "perTrade": 1,
                "rank": 0,
                "visible": true,
                "createdAt": "2017-08-12T21:42:28Z",
                "updatedAt": "2025-06-21T04:03:38Z",
                "itemId": "54a74455e779892d5e5156b9",
                "user": {
                  "id": "5678a156cbfa8f02c9b814c3",
                  "ingameName": "Ealirinineomh",
                  "slug": "ealirinineomh",
                  "avatar": "user/avatar/5678a156cbfa8f02c9b814c3.png?0d832d1017240078ecf4bdeb0d08a101",
                  "reputation": 2123,
                  "platform": "pc",
                  "crossplay": true,
                  "locale": "en",
                  "status": "offline",
                  "activity": {
                    "type": "UNKNOWN",
                    "details": "unknown"
                  },
                  "lastSeen": "2026-02-09T07:44:15Z"
                }
              }
            ],
            "error": null
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
      Bypass.expect_once(bypass, "GET", "/v2/orders/item/gilded_truth", fn conn ->
        body =
          """
          {
            "apiVersion": "0.22.7",
            "data": [
              {
                "id": "5f3188fb86284f0106dd9151",
                "type": "sell",
                "platinum": 20,
                "quantity": 1,
                "perTrade": 1,
                "rank": 3,
                "visible": true,
                "createdAt": "2020-08-10T17:50:51Z",
                "updatedAt": "2026-02-04T15:33:54Z",
                "itemId": "54a74454e779892d5e515664",
                "user": {
                  "id": "5c6a8a5024e70a06bb24f217",
                  "ingameName": "iRobot396",
                  "slug": "irobot396",
                  "reputation": 13,
                  "platform": "pc",
                  "crossplay": true,
                  "locale": "en",
                  "status": "offline",
                  "activity": {
                    "type": "UNKNOWN",
                    "details": "unknown"
                  },
                  "lastSeen": "2026-02-08T14:27:38Z"
                }
              },
              {
                "id": "5f7e2649e6527b026b68fe19",
                "type": "sell",
                "platinum": 50,
                "quantity": 1,
                "perTrade": 1,
                "rank": 3,
                "visible": true,
                "createdAt": "2020-10-07T20:34:17Z",
                "updatedAt": "2023-09-14T03:48:24Z",
                "itemId": "54a74454e779892d5e515664",
                "user": {
                  "id": "5b34e9633048b2074d1f329a",
                  "ingameName": "-AoD-choobie",
                  "slug": "aod-choobie",
                  "avatar": "user/avatar/5b34e9633048b2074d1f329a.png?b08ea71aa1121c7c8a121a26e7bc1bc9",
                  "reputation": 3778,
                  "platform": "pc",
                  "crossplay": true,
                  "locale": "en",
                  "status": "offline",
                  "activity": {
                    "type": "UNKNOWN",
                    "details": "unknown"
                  },
                  "lastSeen": "2026-02-09T07:06:36Z"
                }
              },
              {
                "id": "5f89c2a905bd9703d1396552",
                "type": "sell",
                "platinum": 20,
                "quantity": 97,
                "perTrade": 1,
                "rank": 3,
                "visible": true,
                "createdAt": "2020-10-16T15:56:25Z",
                "updatedAt": "2024-10-18T13:49:22Z",
                "itemId": "54a74454e779892d5e515664",
                "user": {
                  "id": "5e3fd7b1f6b99c00ceb3a209",
                  "ingameName": "murock123",
                  "slug": "murock123",
                  "reputation": 20,
                  "platform": "pc",
                  "crossplay": true,
                  "locale": "en",
                  "status": "offline",
                  "activity": {
                    "type": "UNKNOWN",
                    "details": "unknown"
                  },
                  "lastSeen": "2026-02-09T16:14:13Z"
                }
              }
            ],
            "error": null
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
      Bypass.expect_once(bypass, "GET", "/v2/orders/item/blade_of_truth", fn conn ->
        body =
          """
          {
            "apiVersion": "0.22.7",
            "data": [
              {
                "id": "59f6f221b80847001296269f",
                "type": "sell",
                "platinum": 20,
                "quantity": 1,
                "perTrade": 1,
                "rank": 0,
                "visible": true,
                "createdAt": "2017-10-30T09:34:25Z",
                "updatedAt": "2018-07-14T04:45:42Z",
                "itemId": "54a74454e779892d5e515645",
                "user": {
                  "id": "592c48150f31396fd2e2e813",
                  "ingameName": "..Symbiote.Streak..",
                  "slug": "symbiote-streak",
                  "avatar": "user/avatar/592c48150f31396fd2e2e813.png?5a911f9e3ab57097dda337294d5f2f7d",
                  "reputation": 34,
                  "platform": "pc",
                  "crossplay": true,
                  "locale": "en",
                  "status": "ingame",
                  "activity": {
                    "type": "UNKNOWN",
                    "details": "unknown"
                  },
                  "lastSeen": "2026-02-09T15:54:32Z"
                }
              },
              {
                "id": "5d4f1064c8c6c90046e4ad01",
                "type": "sell",
                "platinum": 24,
                "quantity": 1,
                "perTrade": 1,
                "rank": 3,
                "visible": true,
                "createdAt": "2019-08-10T18:43:48Z",
                "updatedAt": "2026-02-04T15:29:00Z",
                "itemId": "54a74454e779892d5e515645",
                "user": {
                  "id": "5c6a8a5024e70a06bb24f217",
                  "ingameName": "iRobot396",
                  "slug": "irobot396",
                  "reputation": 13,
                  "platform": "pc",
                  "crossplay": true,
                  "locale": "en",
                  "status": "ingame",
                  "activity": {
                    "type": "UNKNOWN",
                    "details": "unknown"
                  },
                  "lastSeen": "2026-02-08T14:27:38Z"
                }
              },
              {
                "id": "5e7b5825dcc19804ce3de1cb",
                "type": "sell",
                "platinum": 15,
                "quantity": 1,
                "perTrade": 1,
                "rank": 3,
                "visible": true,
                "createdAt": "2020-03-25T13:09:57Z",
                "updatedAt": "2026-01-11T13:42:28Z",
                "itemId": "54a74454e779892d5e515645",
                "user": {
                  "id": "5e7532518deffd04432c6cbe",
                  "ingameName": "LeytoRen",
                  "slug": "leytoren",
                  "reputation": 2,
                  "platform": "pc",
                  "crossplay": true,
                  "locale": "en",
                  "status": "ingame",
                  "activity": {
                    "type": "UNKNOWN",
                    "details": "unknown"
                  },
                  "lastSeen": "2026-02-08T22:31:06Z"
                }
              }
            ],
            "error": null
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
      Bypass.expect(bypass, "POST", "/v2/order", fn conn ->
        {:ok, req_body, _req_conn} = Plug.Conn.read_body(conn)
        decoded_request = Jason.decode!(req_body)

        response_body =
          case Map.get(decoded_request, "itemId") do
            # Scattered Justice
            "54a74454e779892d5e5155f5" ->
              assert Map.get(decoded_request, "platinum") == 20
              assert Map.get(decoded_request, "quantity") == 1
              assert Map.get(decoded_request, "rank") == 0
              assert Map.get(decoded_request, "type") == "sell"
              assert Map.get(decoded_request, "visible") == true

              """
              {
                "apiVersion": "0.22.7",
                "data": {
                  "id": "698da92fa7a2008a73b1b930",
                  "type": "sell",
                  "platinum": 20,
                  "quantity": 1,
                  "perTrade": 1,
                  "rank": 0,
                  "visible": true,
                  "createdAt": "2026-02-12T10:19:27Z",
                  "updatedAt": "2026-02-12T10:19:27Z",
                  "itemId": "54a74454e779892d5e5155f5"
                },
                "error": null
              }
              """

            # Blade of Truth
            "54a74454e779892d5e515645" ->
              assert Map.get(decoded_request, "platinum") == 20
              assert Map.get(decoded_request, "quantity") == 1
              assert Map.get(decoded_request, "rank") == 0
              assert Map.get(decoded_request, "type") == "sell"
              assert Map.get(decoded_request, "visible") == true

              """
              {
                "apiVersion": "0.22.7",
                "data": {
                  "id": "698a1032a7a2008a73ad0d23",
                  "type": "sell",
                  "platinum": 20,
                  "quantity": 1,
                  "perTrade": 1,
                  "rank": 0,
                  "visible": true,
                  "createdAt": "2026-02-09T16:49:54Z",
                  "updatedAt": "2026-02-09T16:49:54Z",
                  "itemId": "54a74454e779892d5e515645"
                },
                "error": null
              }
              """

            # Gilded Truth
            "54a74454e779892d5e515664" ->
              assert Map.get(decoded_request, "platinum") == 16
              assert Map.get(decoded_request, "quantity") == 1
              assert Map.get(decoded_request, "rank") == 0
              assert Map.get(decoded_request, "type") == "sell"
              assert Map.get(decoded_request, "visible") == true

              """
              {
                "apiVersion": "0.22.7",
                "data": {
                  "id": "698a109a6a51e1b3b0f36c73",
                  "type": "sell",
                  "platinum": 16,
                  "quantity": 1,
                  "perTrade": 1,
                  "rank": 0,
                  "visible": true,
                  "createdAt": "2026-02-09T16:51:38Z",
                  "updatedAt": "2026-02-09T16:51:38Z",
                  "itemId": "54a74454e779892d5e515664"
                },
                "error": null
              }
              """

            # Justice Blades
            "54a74455e779892d5e5156b9" ->
              assert Map.get(decoded_request, "platinum") == 21
              assert Map.get(decoded_request, "quantity") == 1
              assert Map.get(decoded_request, "rank") == 0
              assert Map.get(decoded_request, "type") == "sell"
              assert Map.get(decoded_request, "visible") == true
              """
              {
                "apiVersion": "0.22.7",
                "data": {
                  "id": "698a10d86a51e1b3b0f36cd0",
                  "type": "sell",
                  "platinum": 21,
                  "quantity": 1,
                  "perTrade": 1,
                  "rank": 0,
                  "visible": true,
                  "createdAt": "2026-02-09T16:52:40Z",
                  "updatedAt": "2026-02-09T16:52:40Z",
                  "itemId": "54a74455e779892d5e5156b9"
                },
                "error": null
              }
              """

            _ ->
              throw("Malformed request body: #{req_body}")
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
      assert_receive({:activate, {:ok, {:price_calculated, "Scattered Justice", 20, 1, 4}}}, @timeout)
      assert_receive({:activate, {:ok, {:price_calculated, "Blade of Truth", 20, 2, 4}}}, @timeout)
      assert_receive({:activate, {:ok, {:price_calculated, "Gilded Truth", 16, 3, 4}}}, @timeout)
      assert_receive({:activate, {:ok, {:price_calculated, "Justice Blades", 21, 4, 4}}}, @timeout)
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

      _manager_pid = start_supervised(ManagerSupervisor)
      :ok = Manager.login(credentials, false)

      assert_receive({:login, {:ok, %User{patreon?: false, ingame_name: "Fl4m3", slug: "fl4m3"}}}, @timeout)

      %{
        bypass: bypass
      }
    end

    test "deactivate some syndicates that are active and reactivates the remaining ones", %{bypass: bypass} do
      Bypass.expect(bypass, "GET", "/v2/orders/user/fl4m3", fn conn ->
        body =
          # "itemId": "54a74454e779892d5e5155f5" -> "Scattered Justice"
          # "itemId": "54a74455e779892d5e5156b9" -> "Justice Blades"
          # "itemId": "54a74454e779892d5e515664" -> "Gilded Truth"
          # "itemId": "54a74454e779892d5e515645" -> "Blade of Truth"
          # "itemId": "54a74454e779892d5e5155ee" -> "Entropy Flight"
          """
          {
            "apiVersion": "0.22.7",
            "data": [
              {
                "id": "698db406a7a2008a73b1c83a",
                "type": "sell",
                "platinum": 15,
                "quantity": 1,
                "perTrade": 1,
                "rank": 0,
                "visible": true,
                "createdAt": "2026-02-12T11:05:42Z",
                "updatedAt": "2026-02-12T11:05:42Z",
                "itemId": "54a74454e779892d5e5155f5"
              },
              {
                "id": "698db423a7a2008a73b1c86c",
                "type": "sell",
                "platinum": 16,
                "quantity": 1,
                "perTrade": 1,
                "rank": 0,
                "visible": true,
                "createdAt": "2026-02-12T11:06:11Z",
                "updatedAt": "2026-02-12T11:06:11Z",
                "itemId": "54a74455e779892d5e5156b9"
              },
              {
                "id": "698db43c6a51e1b3b0f87626",
                "type": "sell",
                "platinum": 14,
                "quantity": 1,
                "perTrade": 1,
                "rank": 0,
                "visible": true,
                "createdAt": "2026-02-12T11:06:36Z",
                "updatedAt": "2026-02-12T11:06:36Z",
                "itemId": "54a74454e779892d5e515664"
              },
              {
                "id": "698db45da7a2008a73b1c8d1",
                "type": "sell",
                "platinum": 17,
                "quantity": 1,
                "perTrade": 1,
                "rank": 0,
                "visible": true,
                "createdAt": "2026-02-12T11:07:09Z",
                "updatedAt": "2026-02-12T11:07:09Z",
                "itemId": "54a74454e779892d5e515645"
              },
              {
                "id": "698db475a7a2008a73b1c91d",
                "type": "sell",
                "platinum": 14,
                "quantity": 1,
                "perTrade": 1,
                "rank": 0,
                "visible": true,
                "createdAt": "2026-02-12T11:07:33Z",
                "updatedAt": "2026-02-12T11:07:33Z",
                "itemId": "54a74454e779892d5e5155ee"
              }
            ],
            "error": null
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

      # delete "Scattered Justice"
      Bypass.expect_once(bypass, "DELETE", "/v2/order/698db406a7a2008a73b1c83a", fn conn ->
        body =
          """
          {
            "apiVersion": "0.22.7",
            "data": {
              "id": "698db406a7a2008a73b1c83a",
              "type": "sell",
              "platinum": 15,
              "quantity": 1,
              "perTrade": 1,
              "rank": 0,
              "visible": true,
              "createdAt": "2026-02-12T11:05:42Z",
              "updatedAt": "2026-02-12T11:05:42Z",
              "itemId": "54a74454e779892d5e5155f5"
            },
            "error": null
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

      # delete "Justice Blades"
      Bypass.expect_once(bypass, "DELETE", "/v2/order/698db423a7a2008a73b1c86c", fn conn ->
        body =
          """
          {
            "apiVersion": "0.22.7",
            "data": {
              "id": "698db423a7a2008a73b1c86c",
              "type": "sell",
              "platinum": 16,
              "quantity": 1,
              "perTrade": 1,
              "rank": 0,
              "visible": true,
              "createdAt": "2026-02-12T11:06:11Z",
              "updatedAt": "2026-02-12T11:06:11Z",
              "itemId": "54a74455e779892d5e5156b9"
            },
            "error": null
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

      # delete "Gilded Truth"
      Bypass.expect_once(bypass, "DELETE", "/v2/order/698db43c6a51e1b3b0f87626", fn conn ->
        body =
          """
          {
            "apiVersion": "0.22.7",
            "data": {
              "id": "698db43c6a51e1b3b0f87626",
              "type": "sell",
              "platinum": 14,
              "quantity": 1,
              "perTrade": 1,
              "rank": 0,
              "visible": true,
              "createdAt": "2026-02-12T11:06:36Z",
              "updatedAt": "2026-02-12T11:06:36Z",
              "itemId": "54a74454e779892d5e515664"
            },
            "error": null
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

      # delete "Blade of Truth"
      Bypass.expect_once(bypass, "DELETE", "/v2/order/698db45da7a2008a73b1c8d1", fn conn ->
        body =
          """
          {
            "apiVersion": "0.22.7",
            "data": {
              "id": "698db45da7a2008a73b1c8d1",
              "type": "sell",
              "platinum": 17,
              "quantity": 1,
              "perTrade": 1,
              "rank": 0,
              "visible": true,
              "createdAt": "2026-02-12T11:07:09Z",
              "updatedAt": "2026-02-12T11:07:09Z",
              "itemId": "54a74454e779892d5e515645"
            },
            "error": null
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

      # delete "Entropy Flight"
      Bypass.expect_once(bypass, "DELETE", "/v2/order/698db475a7a2008a73b1c91d", fn conn ->
        body =
          """
          {
            "apiVersion": "0.22.7",
            "data": {
              "id": "698db475a7a2008a73b1c91d",
              "type": "sell",
              "platinum": 14,
              "quantity": 1,
              "perTrade": 1,
              "rank": 0,
              "visible": true,
              "createdAt": "2026-02-12T11:07:33Z",
              "updatedAt": "2026-02-12T11:07:33Z",
              "itemId": "54a74454e779892d5e5155ee"
            },
            "error": null
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

      Bypass.expect(bypass, "GET", "/v2/orders/user/fl4m3", fn conn ->
        body =
          """
          {
            "apiVersion": "0.22.7",
            "data": [],
            "error": null
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

      Bypass.expect_once(bypass, "GET", "/v2/orders/item/entropy_flight", fn conn ->
        body =
        """
        {
          "apiVersion": "0.22.7",
          "data": [
            {
              "id": "5b585b07f3a59e042c03cf24",
              "type": "sell",
              "platinum": 14,
              "quantity": 1,
              "perTrade": 1,
              "rank": 0,
              "visible": true,
              "createdAt": "2018-07-25T11:12:07Z",
              "updatedAt": "2021-02-06T17:06:03Z",
              "itemId": "54a74454e779892d5e5155ee",
              "user": {
                "id": "5b5855dd047f250441454198",
                "ingameName": "alikis",
                "slug": "alikis",
                "avatar": "user/avatar/5b5855dd047f250441454198.png?04fc1fd688d560f1a70db92e7dfd5bfe",
                "reputation": 7,
                "platform": "pc",
                "crossplay": true,
                "locale": "en",
                "status": "ingame",
                "activity": {
                  "type": "UNKNOWN",
                  "details": "unknown"
                },
                "lastSeen": "2026-02-12T02:24:46Z"
              }
            },
            {
              "id": "5d287a9249d0a800955d5fc0",
              "type": "sell",
              "platinum": 15,
              "quantity": 1,
              "perTrade": 1,
              "rank": 3,
              "visible": true,
              "createdAt": "2019-07-12T12:18:26Z",
              "updatedAt": "2026-02-04T15:27:33Z",
              "itemId": "54a74454e779892d5e5155ee",
              "user": {
                "id": "5c6a8a5024e70a06bb24f217",
                "ingameName": "iRobot396",
                "slug": "irobot396",
                "reputation": 13,
                "platform": "pc",
                "crossplay": true,
                "locale": "en",
                "status": "ingame",
                "activity": {
                  "type": "UNKNOWN",
                  "details": "unknown"
                },
                "lastSeen": "2026-02-12T11:13:27Z"
              }
            },
            {
              "id": "5f7e2984fb02fe027ba66363",
              "type": "sell",
              "platinum": 100,
              "quantity": 3,
              "perTrade": 1,
              "rank": 3,
              "visible": true,
              "createdAt": "2020-10-07T20:48:04Z",
              "updatedAt": "2023-09-14T03:45:36Z",
              "itemId": "54a74454e779892d5e5155ee",
              "user": {
                "id": "5b34e9633048b2074d1f329a",
                "ingameName": "-AoD-choobie",
                "slug": "aod-choobie",
                "avatar": "user/avatar/5b34e9633048b2074d1f329a.png?b08ea71aa1121c7c8a121a26e7bc1bc9",
                "reputation": 3778,
                "platform": "pc",
                "crossplay": true,
                "locale": "en",
                "status": "ingame",
                "activity": {
                  "type": "UNKNOWN",
                  "details": "unknown"
                },
                "lastSeen": "2026-02-12T07:17:05Z"
              }
            }
          ],
          "error": null
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

      # Post Sell order for "Entropy Flight"
      Bypass.expect_once(bypass, "POST", "/v2/order", fn conn ->
        {:ok, json_request_body, _req_conn} = Plug.Conn.read_body(conn)

        decoded_request_body = Jason.decode!(json_request_body)

        assert decoded_request_body == %{
          "itemId" => "54a74454e779892d5e5155ee",
          "type" => "sell",
          "visible" => true,
          "platinum" => 14,
          "quantity" => 1,
          "rank" => 0
        }

        response =
          """
          {
            "apiVersion": "0.22.7",
            "data": {
              "id": "698db9896a51e1b3b0f87e31",
              "type": "sell",
              "platinum": 14,
              "quantity": 1,
              "perTrade": 1,
              "rank": 0,
              "visible": true,
              "createdAt": "2026-02-12T11:29:13Z",
              "updatedAt": "2026-02-12T11:29:13Z",
              "itemId": "54a74454e779892d5e5155ee"
            },
            "error": null
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

  describe "login" do
    setup do
      create_setup_file()
      on_exit(&reset_setup_file/0)

      bypass = Bypass.open(port: 8082)
      credentials = Credentials.new("an_email", "a_password")
      authorization = Authorization.new(%{"cookie" => "a_cookie", "token" => "a_token"})
      user = User.new(%{"ingame_name" => "Fl4m3", "slug" => "fl4m3", "patreon?" => false})

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
          "{\"payload\": {\"user\": {\"has_mail\": true, \"written_reviews\": 0, \"region\": \"en\", \"banned\": false, \"anonymous\": false, \"role\": \"user\", \"reputation\": 84, \"ingame_name\": \"Fl4m3Ph03n1x\", \"slug\": \"fl4m3ph03n1x\", \"platform\": \"pc\", \"unread_messages\": 0, \"background\": null, \"check_code\": \"66BAPR88DLLZ\", \"avatar\": \"user/avatar/584d425cd3ffb630c3f9df42.png?0a8ad917dc66b85aa69520d70a31dafb\", \"verification\": true, \"linked_accounts\": {\"steam_profile\": true, \"patreon_profile\": false, \"xbox_profile\": false, \"discord_profile\": false, \"github_profile\": false}, \"id\": \"584d425cd3ffb630c3f9df42\", \"locale\": \"en\"}}}"

        conn
        |> Plug.Conn.put_resp_header(
          "Set-Cookie",
          "JWT=new_cookie; Domain=.warframe.market; Expires=Tue, 21-Mar-2023 14:41:06 GMT; Secure; HttpOnly; Path=/; SameSite=Lax"
        )
        |> Plug.Conn.resp(200, body)
      end)

      _manager_pid = start_supervised(ManagerSupervisor)
      :ok = Manager.login(credentials, false)

      assert_receive({:login, {:ok, %User{patreon?: false, ingame_name: "Fl4m3Ph03n1x", slug: "fl4m3ph03n1x"}}}, @timeout)
    end

    test "logs in user correctly when there is previous login data", %{credentials: credentials} do
      _manager_pid = start_supervised(ManagerSupervisor)
      :ok = Manager.login(credentials, false)

      assert_receive({:login, {:ok, %User{patreon?: false, ingame_name: "Fl4m3", slug: "fl4m3"}}}, @timeout)
    end
  end

  describe "recover_login" do
    setup do
      create_setup_file()
      on_exit(&reset_setup_file/0)

      credentials = Credentials.new("an_email", "a_password")
      authorization = Authorization.new(%{"cookie" => "a_cookie", "token" => "a_token"})
      user = User.new(%{"ingame_name" => "Fl4m3", "slug" => "fl4m3", "patreon?" => false})

      %{
        credentials: credentials,
        authorization: authorization,
        user: user
      }
    end

    test "returns user when successful" do
      _manager_pid = start_supervised(ManagerSupervisor)

      assert Manager.recover_login() == {:ok, %User{patreon?: false, ingame_name: "Fl4m3", slug: "fl4m3"}}
    end

    test "returns nil if no login session is found" do
      reset_setup_file()

      _manager_pid = start_supervised(ManagerSupervisor)

      assert Manager.recover_login() == {:ok, nil}
    end
  end

  describe "logout" do
    setup do
      create_setup_file()
      on_exit(&reset_setup_file/0)

      credentials = Credentials.new("an_email", "a_password")
      user = User.new(%{"ingame_name" => "Fl4m3", "slug" => "fl4m3", "patreon?" => false})

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

  describe "syndicates" do
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
