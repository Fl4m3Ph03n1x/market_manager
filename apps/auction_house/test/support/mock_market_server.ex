defmodule AuctionHouse.MockMarketServer do
  @moduledoc """
  Mock server that contains pre fabricated responses to make integration
  tests.
  """

  use Plug.Router

  alias Plug.Conn

  plug(Plug.Parsers,
    parsers: [:json],
    pass: ["text/*"],
    json_decoder: Jason
  )

  plug(:match)
  plug(:dispatch)

  post "/v1/profile/orders" do
    case conn.params do
      %{"item_id" => _id} ->
        success(conn, place_order_ok_response())
    end
  end

  delete("/v1/profile/orders/:id", do: success(conn, delete_order_ok_response()))

  get "/v1/items/:item_name/orders", do: success(conn, get_orders_ok_response())

  defp success(conn, body), do: Conn.send_resp(conn, 200, Jason.encode!(body))

  defp place_order_ok_response,
    do: %{
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

  defp delete_order_ok_response, do:
    %{"payload" => %{"order_id" => "5ee71a2604d55c0a5cbdc3c2"}}

  defp get_orders_ok_response, do:
    %{
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
              "status" => "offline"
            },
            "visible" => true
          },
          %{
            "creation_date" => "2019-02-08T22:11:22.000+00:00",
            "id" => "5c5dfe8a83d1620563a75a7d",
            "last_update" => "2020-07-02T14:53:06.000+00:00",
            "order_type" => "sell",
            "platform" => "pc",
            "platinum" => 30.0,
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
              "status" => "offline"
            },
            "visible" => true
          }
        ]
      }
    }

end
