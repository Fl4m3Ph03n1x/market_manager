defmodule AuctionHouse.HTTPClientTest do
  @moduledoc false

  use ExUnit.Case

  alias AuctionHouse.Data.{Credentials, LoginInfo, Order, OrderInfo}
  alias AuctionHouse.Impl.HTTPClient

  describe "place_oder/2" do
    test "returns order_id if order was placed correctly" do
      # Arrange
      order = %Order{
        order_type: "sell",
        item_id: "54a74454e779892d5e5155d5",
        platinum: 15,
        quantity: 1,
        mod_rank: 0
      }

      deps = %{
        post_fn: fn _url, _body, _headers ->
          {:ok,
           %HTTPoison.Response{
             status_code: 200,
             body: "{\"payload\":{\"order\":{\"id\":\"5ee71a2604d55c0a5cbdc3c2\"}}}"
           }}
        end,
        run_fn: fn _queue_name, func -> func.() end,
        requests_queue: nil,
        authorization: %LoginInfo{cookie: "cookie", token: "token"}
      }

      # Act
      actual = HTTPClient.place_order(order, deps)
      expected = {:ok, "5ee71a2604d55c0a5cbdc3c2"}

      # Assert
      assert actual == expected
    end

    test "returns error if order was already placed" do
      # Arrange
      order = %Order{
        order_type: "sell",
        item_id: "54a74454e779892d5e5155d5",
        platinum: 15,
        quantity: 1,
        mod_rank: 0
      }

      deps = %{
        post_fn: fn _url, _body, _headers ->
          {:ok,
           %HTTPoison.Response{
             status_code: 400,
             body: "{\"error\":{\"_form\":[\"app.post_order.already_created_no_duplicates\"]}}"
           }}
        end,
        run_fn: fn _queue_name, func -> func.() end,
        requests_queue: nil,
        authorization: %LoginInfo{cookie: "cookie", token: "token"}
      }

      # Act
      actual = HTTPClient.place_order(order, deps)
      expected = {:error, :order_already_placed, order}

      # Assert
      assert actual == expected
    end

    test "returns error if item_id of order was invalid" do
      # Arrange
      order = %Order{
        order_type: "sell",
        item_id: "54a74454e779892d5e5155d5",
        platinum: 15,
        quantity: 1,
        mod_rank: 0
      }

      deps = %{
        post_fn: fn _url, _body, _headers ->
          {:ok,
           %HTTPoison.Response{
             status_code: 400,
             body: "{\"error\":{\"item_id\":[\"app.form.invalid\"]}}"
           }}
        end,
        run_fn: fn _queue_name, func -> func.() end,
        requests_queue: nil,
        authorization: %LoginInfo{cookie: "cookie", token: "token"}
      }

      # Act
      actual = HTTPClient.place_order(order, deps)
      expected = {:error, :invalid_item_id, order}

      # Assert
      assert actual == expected
    end

    test "returns error if mod has no level and yet a level was passed" do
      # Arrange
      order = %Order{
        order_type: "sell",
        item_id: "54a74454e779892d5e5155d5",
        platinum: 15,
        quantity: 1,
        mod_rank: 0
      }

      deps = %{
        post_fn: fn _url, _body, _headers ->
          {:ok,
           %HTTPoison.Response{
             status_code: 400,
             body: "{\"error\":{\"mod_rank\":[\"app.form.invalid\"]}}"
           }}
        end,
        run_fn: fn _queue_name, func -> func.() end,
        requests_queue: nil,
        authorization: %LoginInfo{cookie: "cookie", token: "token"}
      }

      # Act
      actual = HTTPClient.place_order(order, deps)
      expected = {:error, :rank_level_non_applicable, order}

      # Assert
      assert actual == expected
    end

    test "returns error if server is unavailable" do
      # Arrange
      order = %Order{
        order_type: "sell",
        item_id: "54a74454e779892d5e5155d5",
        platinum: 15,
        quantity: 1,
        mod_rank: 0
      }

      deps = %{
        post_fn: fn _url, _body, _headers ->
          {:ok,
           %HTTPoison.Response{
             status_code: 503,
             body: "<html><head><title>503 Service Temporarily Unavailable</title></head></html>"
           }}
        end,
        run_fn: fn _queue_name, func -> func.() end,
        requests_queue: nil,
        authorization: %LoginInfo{cookie: "cookie", token: "token"}
      }

      # Act
      actual = HTTPClient.place_order(order, deps)
      expected = {:error, :server_unavailable, order}

      # Assert
      assert actual == expected
    end

    test "returns error if server experiences an internal error" do
      # Arrange
      order = %Order{
        order_type: "sell",
        item_id: "54a74454e779892d5e5155d5",
        platinum: 15,
        quantity: 1,
        mod_rank: 0
      }

      deps = %{
        post_fn: fn _url, _body, _headers ->
          {:ok,
           %HTTPoison.Response{
             status_code: 500,
             body: ""
           }}
        end,
        run_fn: fn _queue_name, func -> func.() end,
        requests_queue: nil,
        authorization: %LoginInfo{cookie: "cookie", token: "token"}
      }

      # Act
      actual = HTTPClient.place_order(order, deps)
      expected = {:error, :internal_server_error, order}

      # Assert
      assert actual == expected
    end

    test "returns error if a generic network error occurred while placing a request" do
      # Arrange
      order = %Order{
        order_type: "sell",
        item_id: "54a74454e779892d5e5155d5",
        platinum: 15,
        quantity: 1,
        mod_rank: 0
      }

      deps = %{
        post_fn: fn _url, _body, _headers ->
          {:error, %HTTPoison.Error{id: nil, reason: :timeout}}
        end,
        run_fn: fn _queue_name, func -> func.() end,
        requests_queue: nil,
        authorization: %LoginInfo{cookie: "cookie", token: "token"}
      }

      # Act
      actual = HTTPClient.place_order(order, deps)
      expected = {:error, :timeout, order}

      # Assert
      assert actual == expected
    end

    test "returns error if user tries to place order without having logged in first" do
      # Arrange
      order = %Order{
        order_type: "sell",
        item_id: "54a74454e779892d5e5155d5",
        platinum: 15,
        quantity: 1,
        mod_rank: 0
      }

      deps = %{
        post_fn: fn _url, _body, _headers ->
          {:ok,
           %HTTPoison.Response{
             status_code: 200,
             body: "{\"payload\":{\"order\":{\"id\":\"5ee71a2604d55c0a5cbdc3c2\"}}}"
           }}
        end,
        run_fn: fn _queue_name, func -> func.() end,
        requests_queue: nil
      }

      # Act
      actual = HTTPClient.place_order(order, deps)
      expected = {:error, :missing_authorization_credentials, order}

      # Assert
      assert actual == expected
    end
  end

  describe "delete_oder/2" do
    test "returns {:ok, order_id} if order was deleted correctly" do
      # Arrange
      order_id = "5ee71a2604d55c0a5cbdc3c2"

      deps = %{
        delete_fn: fn _url, _headers ->
          {:ok,
           %HTTPoison.Response{
             status_code: 200,
             body: "{\"payload\":{\"order_id\":\"5ee71a2604d55c0a5cbdc3c2\"}}"
           }}
        end,
        run_fn: fn _queue_name, func -> func.() end,
        requests_queue: nil,
        authorization: %LoginInfo{cookie: "cookie", token: "token"}
      }

      # Act
      actual = HTTPClient.delete_order(order_id, deps)
      expected = {:ok, "5ee71a2604d55c0a5cbdc3c2"}

      # Assert
      assert actual == expected
    end

    test "returns error if order did not exist" do
      # Arrange
      order_id = "5ee71a2604d55c0a5cbdc3c2"

      deps = %{
        delete_fn: fn _url, _headers ->
          {:ok,
           %HTTPoison.Response{
             status_code: 400,
             body: "{\"error\": {\"order_id\": [\"app.form.invalid\"]}}"
           }}
        end,
        run_fn: fn _queue_name, func -> func.() end,
        requests_queue: nil,
        authorization: %LoginInfo{cookie: "cookie", token: "token"}
      }

      # Act
      actual = HTTPClient.delete_order(order_id, deps)
      expected = {:error, :order_non_existent, "5ee71a2604d55c0a5cbdc3c2"}

      # Assert
      assert actual == expected
    end

    test "returns error if a generic network error occurred while deleting a request" do
      # Arrange
      order_id = "5ee71a2604d55c0a5cbdc3c2"

      deps = %{
        delete_fn: fn _url, _headers ->
          {:error, %HTTPoison.Error{id: nil, reason: :timeout}}
        end,
        run_fn: fn _queue_name, func -> func.() end,
        requests_queue: nil,
        authorization: %LoginInfo{cookie: "cookie", token: "token"}
      }

      # Act
      actual = HTTPClient.delete_order(order_id, deps)
      expected = {:error, :timeout, "5ee71a2604d55c0a5cbdc3c2"}

      # Assert
      assert actual == expected
    end

    test "returns error if server experiences an internal error" do
      # Arrange
      order_id = "5ee71a2604d55c0a5cbdc3c2"

      deps = %{
        delete_fn: fn _url, _headers ->
          {:ok,
           %HTTPoison.Response{
             status_code: 500,
             body: ""
           }}
        end,
        run_fn: fn _queue_name, func -> func.() end,
        requests_queue: nil,
        authorization: %LoginInfo{cookie: "cookie", token: "token"}
      }

      # Act
      actual = HTTPClient.delete_order(order_id, deps)
      expected = {:error, :internal_server_error, order_id}

      # Assert
      assert actual == expected
    end

    test "returns error if user tries to delete order without having logged in first" do
      # Arrange
      order_id = "5ee71a2604d55c0a5cbdc3c2"

      deps = %{}

      # Act
      actual = HTTPClient.delete_order(order_id, deps)
      expected = {:error, :missing_authorization_credentials, order_id}

      # Assert
      assert actual == expected
    end
  end

  describe "get_all_orders/2" do
    test "returns {:ok, [order_info]} if request for orders about item succeeded" do
      # Arrange
      item_name = "Gleaming Blight"

      deps = %{
        get_fn: fn _url, _headers ->
          {:ok,
           %HTTPoison.Response{
             status_code: 200,
             body:
               "{\"payload\":{\"orders\":[{\"order_type\":\"sell\",\"platform\":\"pc\",\"platinum\":45,\"region\":\"en\",\"user\":{\"status\":\"ingame\",\"ingame_name\":\"Fl4m3Ph03n1x\"},\"visible\":true},{\"order_type\":\"sell\",\"platform\":\"pc\",\"platinum\":30,\"region\":\"en\",\"user\":{\"status\":\"ingame\",\"ingame_name\":\"Fl4m3Ph03n1x\"},\"visible\":true}]}}"
           }}
        end,
        run_fn: fn _queue_name, func -> func.() end,
        requests_queue: nil,
        cookie: nil,
        token: nil
      }

      # Act
      actual = HTTPClient.get_all_orders(item_name, deps)

      expected =
        {:ok,
         [
           %OrderInfo{
             order_type: "sell",
             platform: "pc",
             platinum: 45,
             user: %OrderInfo.User{status: "ingame", ingame_name: "Fl4m3Ph03n1x"},
             visible: true
           },
           %OrderInfo{
             order_type: "sell",
             platform: "pc",
             platinum: 30,
             user: %OrderInfo.User{status: "ingame", ingame_name: "Fl4m3Ph03n1x"},
             visible: true
           }
         ]}

      # Assert
      assert actual == expected
    end

    test "returns error if request for orders about item fails" do
      # Arrange
      item_name = "Gleaming Blight"

      deps = %{
        get_fn: fn _url, _headers ->
          {:ok,
           %HTTPoison.Response{
             status_code: 500,
             body: ""
           }}
        end,
        run_fn: fn _queue_name, func -> func.() end,
        requests_queue: nil,
        cookie: nil,
        token: nil
      }

      # Act
      actual = HTTPClient.get_all_orders(item_name, deps)
      expected = {:error, :internal_server_error, "Gleaming Blight"}

      # Assert
      assert actual == expected
    end
  end

  describe "login/2" do
    test "returns LoginInfo if login happens correctly" do
      # Arrange
      credentials = Credentials.new("my_email", "my_password")

      deps = %{
        post_fn: fn _url, _body, _headers ->
          {:ok,
           %HTTPoison.Response{
             headers: [
               {"set-cookie",
                "JWT=new_cookie; Domain=.warframe.market; Expires=Tue, 21-Mar-2023 14:41:06 GMT; Secure; HttpOnly; Path=/; SameSite=Lax"}
             ],
             status_code: 200,
             body:
               "{\"payload\": {\"user\": {\"has_mail\": true, \"written_reviews\": 0, \"region\": \"en\", \"banned\": false, \"anonymous\": false, \"role\": \"user\", \"reputation\": 84, \"ingame_name\": \"Fl4m3Ph03n1x\", \"platform\": \"pc\", \"unread_messages\": 0, \"background\": null, \"check_code\": \"66BAPR88DLLZ\", \"avatar\": \"user/avatar/584d425cd3ffb630c3f9df42.png?0a8ad917dc66b85aa69520d70a31dafb\", \"verification\": true, \"linked_accounts\": {\"steam_profile\": true, \"patreon_profile\": false, \"xbox_profile\": false, \"discord_profile\": false, \"github_profile\": false}, \"id\": \"584d425cd3ffb630c3f9df42\", \"locale\": \"en\"}}}"
           }}
        end,
        encode_fn: &Jason.encode/1,
        decode_fn: &Jason.decode/1,
        parse_document_fn: fn _document ->
          {:ok,
           [
             {"html", [{"lang", "en"}],
              [
                {"head", [], [{"meta", [{"name", "csrf-token"}, {"content", "a_token"}], []}]},
                {"body", [], []}
              ]}
           ]}
        end,
        find_in_document_fn: fn _document, _search ->
          [{"meta", [{"name", "csrf-token"}, {"content", "a_token"}], []}]
        end,
        get_fn: fn _url, _headers ->
          {:ok,
           %HTTPoison.Response{
             status_code: 200,
             headers: [
               {"set-cookie",
                "JWT=old_cookie; Domain=.warframe.market; Expires=Tue, 21-Mar-2023 15:16:03 GMT; Secure; HttpOnly; Path=/; SameSite=Lax"}
             ],
             body: """
             <!DOCTYPE html>
             <html lang=en>
             <head>
                 <meta name="csrf-token" content="a_token">
             </head>
             <body>
             </body>
             </html>
             """
           }}
        end
      }

      # Act
      actual = HTTPClient.login(credentials, deps)

      expected = {:ok, LoginInfo.new("JWT=new_cookie", "a_token", false)}

      # Assert
      assert actual == expected
    end

    test "returns error if request to market signin fails" do
      # Arrange
      credentials = Credentials.new("my_email", "my_password")

      deps = %{
        post_fn: nil,
        encode_fn: &Jason.encode/1,
        parse_document_fn: fn _document ->
          {:ok,
           [
             {"html", [{"lang", "en"}],
              [
                {"head", [], [{"meta", [{"name", "csrf-token"}, {"content", "a_token"}], []}]},
                {"body", [], []}
              ]}
           ]}
        end,
        find_in_document_fn: fn _document, _search ->
          [{"meta", [{"name", "csrf-token"}, {"content", "a_token"}], []}]
        end,
        get_fn: fn _url, _headers ->
          {:ok,
           %HTTPoison.Response{
             status_code: 500,
             headers: [],
             body: "\"Error\""
           }}
        end
      }

      # Act
      actual = HTTPClient.login(credentials, deps)

      expected = {:error, :internal_server_error, credentials}

      # Assert
      assert actual == expected
    end

    test "returns error if parsing html document fails" do
      # Arrange
      credentials = Credentials.new("my_email", "my_password")

      deps = %{
        post_fn: nil,
        encode_fn: &Jason.encode/1,
        parse_document_fn: fn _document ->
          {:error, :failed_to_parse_document}
        end,
        find_in_document_fn: nil,
        get_fn: fn _url, _headers ->
          {:ok, %HTTPoison.Response{status_code: 200, body: "", headers: []}}
        end
      }

      # Act
      actual = HTTPClient.login(credentials, deps)

      expected = {:error, :failed_to_parse_document, credentials}

      # Assert
      assert actual == expected
    end

    test "returns error if it cannot find the XRFC token" do
      # Arrange
      credentials = Credentials.new("my_email", "my_password")

      deps = %{
        post_fn: nil,
        encode_fn: &Jason.encode/1,
        parse_document_fn: fn _document -> {:ok, nil} end,
        find_in_document_fn: fn _document, _search -> [] end,
        get_fn: fn _url, _headers ->
          {:ok, %HTTPoison.Response{status_code: 200, body: "", headers: []}}
        end
      }

      # Act
      actual = HTTPClient.login(credentials, deps)

      expected = {:error, {:xrfc_token_not_found, nil}, credentials}

      # Assert
      assert actual == expected
    end

    test "returns error if it cannot find the cookie" do
      # Arrange
      credentials = Credentials.new("my_email", "my_password")

      deps = %{
        post_fn: nil,
        encode_fn: &Jason.encode/1,
        parse_document_fn: fn _document -> {:ok, nil} end,
        find_in_document_fn: fn _document, _search ->
          [{"meta", [{"name", "csrf-token"}, {"content", nil}], []}]
        end,
        get_fn: fn _url, _headers ->
          {:ok, %HTTPoison.Response{status_code: 200, body: "", headers: []}}
        end
      }

      # Act
      actual = HTTPClient.login(credentials, deps)

      expected = {:error, {:no_cookie_found, []}, credentials}

      # Assert
      assert actual == expected
    end

    test "returns error if it cannot find the JWT inside cookie" do
      # Arrange
      credentials = Credentials.new("my_email", "my_password")

      headers = [
        {"set-cookie",
         "Domain=.warframe.market; Expires=Tue, 21-Mar-2023 15:16:03 GMT; Secure; HttpOnly; Path=/; SameSite=Lax"}
      ]

      deps = %{
        post_fn: nil,
        encode_fn: &Jason.encode/1,
        parse_document_fn: fn _document -> {:ok, nil} end,
        find_in_document_fn: fn _document, _search ->
          [{"meta", [{"name", "csrf-token"}, {"content", nil}], []}]
        end,
        get_fn: fn _url, _headers ->
          {:ok, %HTTPoison.Response{status_code: 200, body: "", headers: headers}}
        end
      }

      # Act
      actual = HTTPClient.login(credentials, deps)

      expected = {:error, {:missing_jwt, headers}, credentials}

      # Assert
      assert actual == expected
    end

    test "returns error if it fails to authenticate credentials" do
      # Arrange
      credentials = Credentials.new("my_email", "my_password")

      post_response = %HTTPoison.Response{
        headers: [
          {"set-cookie",
           "JWT=new_cookie; Domain=.warframe.market; Expires=Tue, 21-Mar-2023 14:41:06 GMT; Secure; HttpOnly; Path=/; SameSite=Lax"}
        ],
        status_code: 400,
        body: "{\"error\": {\"password\": [\"app.account.password_invalid\"]}}"
      }

      deps = %{
        post_fn: fn _url, _body, _headers ->
          {:ok, post_response}
        end,
        encode_fn: &Jason.encode/1,
        decode_fn: &Jason.decode/1,
        parse_document_fn: fn _document ->
          {:ok,
           [
             {"html", [{"lang", "en"}],
              [
                {"head", [], [{"meta", [{"name", "csrf-token"}, {"content", "a_token"}], []}]},
                {"body", [], []}
              ]}
           ]}
        end,
        find_in_document_fn: fn _document, _search ->
          [{"meta", [{"name", "csrf-token"}, {"content", "a_token"}], []}]
        end,
        get_fn: fn _url, _headers ->
          {:ok,
           %HTTPoison.Response{
             status_code: 200,
             headers: [
               {"set-cookie",
                "JWT=old_cookie; Domain=.warframe.market; Expires=Tue, 21-Mar-2023 15:16:03 GMT; Secure; HttpOnly; Path=/; SameSite=Lax"}
             ],
             body: """
             <!DOCTYPE html>
             <html lang=en>
             <head>
                 <meta name="csrf-token" content="a_token">
             </head>
             <body>
             </body>
             </html>
             """
           }}
        end
      }

      # Act
      actual = HTTPClient.login(credentials, deps)

      expected = {:error, :wrong_password, credentials}

      # Assert
      assert actual == expected
    end

    test "returns error if it fails to decode body from post auth response" do
      # Arrange
      credentials = Credentials.new("my_email", "my_password")

      deps = %{
        post_fn: fn _url, _body, _headers ->
          {:ok,
           %HTTPoison.Response{
             headers: [
               {"set-cookie",
                "JWT=new_cookie; Domain=.warframe.market; Expires=Tue, 21-Mar-2023 14:41:06 GMT; Secure; HttpOnly; Path=/; SameSite=Lax"}
             ],
             status_code: 200,
             body: "{\"payload\": }"
           }}
        end,
        encode_fn: &Jason.encode/1,
        decode_fn: &Jason.decode/1,
        parse_document_fn: fn _document ->
          {:ok,
           [
             {"html", [{"lang", "en"}],
              [
                {"head", [], [{"meta", [{"name", "csrf-token"}, {"content", "a_token"}], []}]},
                {"body", [], []}
              ]}
           ]}
        end,
        find_in_document_fn: fn _document, _search ->
          [{"meta", [{"name", "csrf-token"}, {"content", "a_token"}], []}]
        end,
        get_fn: fn _url, _headers ->
          {:ok,
           %HTTPoison.Response{
             status_code: 200,
             headers: [
               {"set-cookie",
                "JWT=old_cookie; Domain=.warframe.market; Expires=Tue, 21-Mar-2023 15:16:03 GMT; Secure; HttpOnly; Path=/; SameSite=Lax"}
             ],
             body: """
             <!DOCTYPE html>
             <html lang=en>
             <head>
                 <meta name="csrf-token" content="a_token">
             </head>
             <body>
             </body>
             </html>
             """
           }}
        end
      }

      # Act
      actual = HTTPClient.login(credentials, deps)

      expected =
        {:error,
         {:unable_to_decode_body,
          %Jason.DecodeError{position: 12, token: nil, data: "{\"payload\": }"}}, credentials}

      # Assert
      assert actual == expected
    end

    test "returns error if body does not have payload" do
      # Arrange
      credentials = Credentials.new("my_email", "my_password")

      deps = %{
        post_fn: fn _url, _body, _headers ->
          {:ok,
           %HTTPoison.Response{
             headers: [
               {"set-cookie",
                "JWT=new_cookie; Domain=.warframe.market; Expires=Tue, 21-Mar-2023 14:41:06 GMT; Secure; HttpOnly; Path=/; SameSite=Lax"}
             ],
             status_code: 200,
             body: "{\"data\": 1}"
           }}
        end,
        encode_fn: &Jason.encode/1,
        decode_fn: &Jason.decode/1,
        parse_document_fn: fn _document ->
          {:ok,
           [
             {"html", [{"lang", "en"}],
              [
                {"head", [], [{"meta", [{"name", "csrf-token"}, {"content", "a_token"}], []}]},
                {"body", [], []}
              ]}
           ]}
        end,
        find_in_document_fn: fn _document, _search ->
          [{"meta", [{"name", "csrf-token"}, {"content", "a_token"}], []}]
        end,
        get_fn: fn _url, _headers ->
          {:ok,
           %HTTPoison.Response{
             status_code: 200,
             headers: [
               {"set-cookie",
                "JWT=old_cookie; Domain=.warframe.market; Expires=Tue, 21-Mar-2023 15:16:03 GMT; Secure; HttpOnly; Path=/; SameSite=Lax"}
             ],
             body: """
             <!DOCTYPE html>
             <html lang=en>
             <head>
                 <meta name="csrf-token" content="a_token">
             </head>
             <body>
             </body>
             </html>
             """
           }}
        end
      }

      # Act
      actual = HTTPClient.login(credentials, deps)

      expected = {:error, {:payload_not_found, %{"data" => 1}}, credentials}

      # Assert
      assert actual == expected
    end
  end
end
