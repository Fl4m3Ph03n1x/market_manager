defmodule MarketManager.FakeMarketServer do
  use Plug.Router

  alias Plug.Conn

  plug Plug.Parsers, parsers: [:json],
                    pass:  ["text/*"],
                    json_decoder: Jason

  plug :match
  plug :dispatch

  post "/v1/profile/orders" do
    success(conn, place_order_ok_response())
    # case conn.params do
    #   %{"name" =>"place_order_ok_response"} ->
    #     success(conn, place_order_ok_response())
    #   %{"name" =>"place_order_error_duplicated_response"} ->
    #     failure(conn, place_order_error_duplicated_response())
    #   %{"name" =>"place_order_erorr_non_existent_item_response"} ->
    #     failure(conn, place_order_erorr_non_existent_item_response())
    # end
  end

  # delete "/v1/profile/orders/:id" do

  # end

  defp success(conn, body), do:
    Conn.send_resp(conn, 200, Jason.encode!(body))

  defp failure(conn, body), do:
    Conn.send_resp(conn, 400, Jason.encode!(body))


  defp place_order_ok_response() do
    %{
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
  end

  defp place_order_error_duplicated_response() do
    "{\"error\": {\"_form\": [\"app.post_order.already_created_no_duplicates\"]}}"
  end

  defp place_order_erorr_non_existent_item_response() do
    "{\"error\": {\"item_id\": [\"app.form.invalid\"]}}"
  end
end

