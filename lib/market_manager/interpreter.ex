defmodule MarketManager.Interpreter do
  @moduledoc """
  Core of the market manager, where all the logic and communication with outer
  layers is. Currently, it works more like a bridge between the different ports
  of the application and manages data between them.
  """
  use Rop

  alias MarketManager
  alias MarketManager.{PriceAnalyst, Store}

  @type order_request :: %{
    (order_type :: String.t) => String.t,
    (item_id :: String.t) => String.t,
    (platinum :: String.t) => non_neg_integer,
    (quantity :: String.t) => non_neg_integer,
    (mod_rank :: String.t) => non_neg_integer
  }
  @type order_request_without_rank :: %{
    (order_type :: String.t) => String.t,
    (item_id :: String.t) => String.t,
    (platinum :: String.t) => non_neg_integer,
    (quantity :: String.t) => non_neg_integer
  }

  @default_deps [
    store: MarketManager.Store.FileSystem,
    auction_house: MarketManager.AuctionHouse.HTTPClient
  ]

  ##########
  # Public #
  ##########

  # curl 'https://api.warframe.market/v1/items/kitgun_riven_mod_(veiled)/orders'
  # -H 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10.14; rv:78.0) Gecko/20100101 Firefox/78.0'
  # -H 'Accept: application/json'
  # -H 'Accept-Language: en-US,en;q=0.5'
  # --compressed
  # -H 'Referer: https://warframe.market/items/kitgun_riven_mod_(veiled)'
  # -H 'content-type: application/json'
  # -H 'language: en'
  # -H 'platform: pc'
  # -H 'Origin: https://warframe.market'
  # -H 'DNT: 1'
  # -H 'Connection: keep-alive'
  # -H 'Cookie: JWT=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzaWQiOiJnTzFSWnpXS0pEM0dwTW56MzlzQTdjbXRmeVVrNjg4VCIsImNzcmZfdG9rZW4iOiIwNGVjNmU0MWIyYTg1N2NiNTYxNzJlOTViMjk1NjMxYzVhZTEyN2FlIiwiZXhwIjoxNjAxMTA3ODg0LCJpYXQiOjE1OTU5MjM4ODQsImlzcyI6Imp3dCIsImF1ZCI6Imp3dCIsImF1dGhfdHlwZSI6ImNvb2tpZSIsInNlY3VyZSI6ZmFsc2UsImxvZ2luX3VhIjoiYidNb3ppbGxhLzUuMCAoTWFjaW50b3NoOyBJbnRlbCBNYWMgT1MgWCAxMC4xNDsgcnY6NzYuMCkgR2Vja28vMjAxMDAxMDEgRmlyZWZveC83Ni4wJyIsImxvZ2luX2lwIjoiYic4MC43MS4wLjIwOSciLCJqd3RfaWRlbnRpdHkiOiJCZFdQR3F4WlU1RW56SUJXUDhHU3VYNEhBNE84RVlDUSJ9.YDHDLPATCpO1LVHROVFvFQuJG41sr4PjrHef55NxyYk; _ga=GA1.2.1094921180.1591686701; __cfduid=d1582beb0dccb9976006f828da535db251594807955'

  @spec activate(MarketManager.syndicate, MarketManager.strategy, keyword) ::
    MarketManager.activate_response
  def activate(syndicate, strategy, deps \\ @default_deps), do:
    syndicate
    |> list_products(deps[:store])
    >>> calculate_prices(strategy, deps[:auction_house])
    # >>> make_place_requests(deps[:auction_house])
    # |> save_orders(syndicate, deps[:store])
    # |> to_human_response(:place)

  @spec deactivate(MarketManager.syndicate, keyword) ::
    MarketManager.deactivate_response
  def deactivate(syndicate, deps \\ @default_deps), do:
    syndicate
    |> list_orders(deps[:store])
    >>> make_delete_requests(deps[:auction_house])
    |> check_non_existent_orders()
    |> delete_orders(syndicate, deps[:store])
    |> to_human_response(:delete)

  ###########
  # Private #
  ###########

  @spec list_products(MarketManager.syndicate, deps :: module)
    :: Store.list_products_response
  defp list_products(syndicate, store), do: store.list_products(syndicate)

  @spec calculate_prices([Store.product], MarketManager.strategy, deps :: module)
  :: {:ok, [Store.product]}
  defp calculate_prices(products, strategy, auction_house_api) do
    products
    |> Enum.map(fn product -> Map.get(product, "name") end)
    |> Enum.map(&auction_house_api.get_all_orders/1)
    |> Enum.map(&calculate_price(&1, strategy))
  end

  defp calculate_price({:ok, all_orders}, strategy), do:
    PriceAnalyst.calculate_price(all_orders, strategy)

  defp calculate_price(_error, _strategy), do: 0

  @spec make_place_requests([Store.product], deps :: module)
    :: {[{:ok, MarketManager.order_id}], [{:error, atom, MarketManager.order_id}]}
  defp make_place_requests(products, auction_house_api), do:
    products
    |> Enum.map(&build_order/1)
    |> Enum.map(&auction_house_api.place_order/1)
    |> Enum.split_with(&status_ok?/1)

  @spec build_order(Store.product) :: order_request | order_request_without_rank
  defp build_order(product) do
    case Map.get(product, "rank") do
      "n/a" ->
        %{
          "order_type" => "sell",
          "item_id" => Map.get(product, "id"),
          "platinum" => Map.get(product, "price"),
          "quantity" => Map.get(product, "quantity", 1)
        }

      _ ->
        %{
          "order_type" => "sell",
          "item_id" => Map.get(product, "id"),
          "platinum" => Map.get(product, "price"),
          "quantity" => Map.get(product, "quantity", 1),
          "mod_rank" => Map.get(product, "rank", 0)
        }
    end
  end

  @spec save_orders(
    {[{:ok, MarketManager.order_id}], [{:error, atom, MarketManager.order_id}]},
    MarketManager.syndicate,
    deps :: module
  ) :: {[{:ok, MarketManager.order_id}], [{:error, atom, MarketManager.order_id} | {:error, any}]}
  defp save_orders({success_resps, failed_resps}, syndicate, store_api) do
    {successfull_saves, failed_saves} =
      success_resps
      |> Enum.map(&get_order_id/1)
      |> Enum.map(&store_api.save_order(&1, syndicate))
      |> Enum.split_with(&status_ok?/1)

    {successfull_saves, failed_resps ++ failed_saves}
  end

  @spec list_orders(MarketManager.syndicate, deps :: module)
    :: Store.list_orders_response
  defp list_orders(syndicate, store), do: store.list_orders(syndicate)

  @spec make_delete_requests([MarketManager.order_id], deps :: module) ::
    {[{:ok, MarketManager.order_id}], [{:error, atom, MarketManager.order_id}]}
  defp make_delete_requests(order_ids, auction_house_api), do:
    order_ids
    |> Enum.map(&auction_house_api.delete_order/1)
    |> Enum.split_with(&status_ok?/1)

  @spec check_non_existent_orders(
    {[{:ok, MarketManager.order_id}], [{:error, atom, MarketManager.order_id}]}
  ) :: {[{:ok, MarketManager.order_id} | {:error, :order_non_existent, MarketManager.order_id}],
        [{:error, atom, MarketManager.order_id}]}
  defp check_non_existent_orders({success_resps, failed_resps}) do
    non_existent_orders =
      Enum.filter(failed_resps, &order_non_existent?/1)

    {success_resps ++ non_existent_orders, failed_resps}
  end

  @spec delete_orders(
    {[{:ok, MarketManager.order_id} | {:error, :order_non_existent, MarketManager.order_id}],
    [{:error, atom, MarketManager.order_id}]},
    MarketManager.syndicate,
    deps :: keyword
  ) :: {[{:ok, MarketManager.order_id}], [{:error, atom, MarketManager.order_id} | {:error, any}]}
  defp delete_orders({success_resps, failed_resps}, syndicate, store_api) do
    {successfull_deletions, failed_deletions} =
      success_resps
      |> Enum.map(&get_order_id/1)
      |> Enum.map(&store_api.delete_order(&1, syndicate))
      |> Enum.split_with(&status_ok?/1)

    {successfull_deletions, failed_resps ++ failed_deletions}
  end

  @spec status_ok?(any) :: boolean
  defp status_ok?({:ok, _data}), do: true
  defp status_ok?(_order), do: false

  @spec get_order_id(
    {:ok, MarketManager.order_id}
    | {:error, :order_non_existent, MarketManager.order_id}
  ) :: MarketManager.order_id
  defp get_order_id({:ok, order_id}), do: order_id
  defp get_order_id({:error, :order_non_existent, order_id}), do: order_id

  @spec order_non_existent?(any) :: boolean
  defp order_non_existent?({:error, :order_non_existent, _order_id}), do: true
  defp order_non_existent?(_), do: false

  @spec to_human_response({[any], [any]}, :delete | :place) ::
    {:ok, :success}
    | {
        :partial_success,
        [failed_orders: [{:error, MarketManager.error_reason, MarketManager.order_id | MarketManager.item_id}, ...]]
      }
    | {
        :error,
        :unable_to_place_requests,
        [{:error, MarketManager.error_reason, MarketManager.order_id | MarketManager.item_id}]
      }
    | {
        :error,
        :unable_to_delete_orders,
        [{:error, MarketManager.error_reason, MarketManager.order_id | MarketManager.item_id}]
      }
  defp to_human_response({successfull, failed}, :place) when successfull == [], do:
    {:error, :unable_to_place_requests, failed}

  defp to_human_response({successfull, failed}, :delete) when successfull == [], do:
    {:error, :unable_to_delete_orders, failed}

  defp to_human_response({_successfull, failed}, _op) when failed == [], do:
    {:ok, :success}

  defp to_human_response({_successfull, failed}, _op), do:
    {:partial_success, [failed_orders: failed]}
end
