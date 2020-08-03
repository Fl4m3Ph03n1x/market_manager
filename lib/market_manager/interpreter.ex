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

  @spec activate(MarketManager.syndicate, MarketManager.strategy, keyword) ::
    MarketManager.activate_response
  def activate(syndicate, strategy, deps \\ @default_deps), do:
    syndicate
    |> list_products(deps[:store])
    >>> calculate_prices(strategy, deps[:auction_house])
    |> make_place_requests(deps[:auction_house])
    |> save_orders(syndicate, deps[:store])
    |> to_human_response(:place)

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

  @spec calculate_prices([Store.product], MarketManager.strategy, deps :: module) :: [Store.product]
  defp calculate_prices(products, strategy, auction_house_api), do:
    Enum.map(products, &update_product_price(&1, strategy, auction_house_api))

  defp calculate_price({:ok, all_orders}, strategy), do:
    PriceAnalyst.calculate_price(all_orders, strategy)

  defp calculate_price(_error, _strategy), do: 0

  defp update_product_price(product, strategy, auction_house_api) do
    new_product_price =
      product
      |> Map.get("name")
      |> auction_house_api.get_all_orders()
      |> calculate_price(strategy)

    Map.put(product, "price", new_product_price)
  end

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
