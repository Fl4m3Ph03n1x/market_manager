defmodule Manager.Interpreter do
  @moduledoc """
  Core of the manager, where all the logic and communication with outer
  layers is. Currently, it works more like a bridge between the different ports
  of the application and manages data between them.
  """

  use Rop

  alias Manager
  alias Manager.PriceAnalyst
  alias Store

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

  @mandatory_keys_login_info ["token", "cookie"]
  @actions ["activate", "deactivate", "setup"]
  @default_deps [
    store: Store,
    auction_house: AuctionHouse
  ]

  ##########
  # Public #
  ##########

  @spec valid_action?(String.t) :: boolean
  def valid_action?(action), do: action in @actions

  @spec activate(Manager.syndicate, Manager.strategy, keyword) ::
    Manager.activate_response
  def activate(syndicate, strategy, deps \\ @default_deps), do:
    syndicate
    |> list_products(deps[:store])
    >>> calculate_prices(strategy, deps[:auction_house])
    |> make_place_requests(deps[:auction_house])
    |> save_orders(syndicate, deps[:store])
    |> to_human_response(:place)

  @spec deactivate(Manager.syndicate, keyword) ::
    Manager.deactivate_response
  def deactivate(syndicate, deps \\ @default_deps), do:
    syndicate
    |> list_orders(deps[:store])
    >>> make_delete_requests(deps[:auction_house])
    |> check_non_existent_orders()
    |> delete_orders(syndicate, deps[:store])
    |> to_human_response(:delete)

  @spec setup(Store.login_info, keyword) :: Manager.setup_response
  def setup(info, deps \\ @default_deps), do:
    info
    |> validate_login_info()
    >>> save_setup(deps[:store])
    |> handle_setup_response(info)

  ###########
  # Private #
  ###########

  @spec list_products(Manager.syndicate, deps :: module)
    :: Store.list_products_response
  defp list_products(syndicate, store), do: store.list_products(syndicate)

  @spec calculate_prices([Store.product], Manager.strategy, deps :: module) :: [Store.product]
  defp calculate_prices(products, strategy, auction_house_api), do:
    Enum.map(products, &update_product_price(&1, strategy, auction_house_api))

  defp update_product_price(product, strategy, auction_house_api), do:
    product
    |> Map.get("name")
    |> auction_house_api.get_all_orders()
    |> calculate_price(strategy, product)
    |> update_price(product)

  @spec calculate_price(any, Manager.strategy, Store.product) :: non_neg_integer
  defp calculate_price({:ok, all_orders}, strategy, product), do:
    PriceAnalyst.calculate_price(product, all_orders, strategy)

  defp calculate_price(_error, _strategy, product), do:
    Map.get(product, "default_price")

  @spec update_price(non_neg_integer, Store.product) :: map
  defp update_price(price, product), do: Map.put(product, "price", price)

  @spec make_place_requests([Store.product], deps :: module)
    :: {[{:ok, Manager.order_id}], [{:error, atom, Manager.order_id}]}
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
    {[{:ok, Manager.order_id}], [{:error, atom, Manager.order_id}]},
    Manager.syndicate,
    deps :: module
  ) :: {[{:ok, Manager.order_id}], [{:error, atom, Manager.order_id} | {:error, any}]}
  defp save_orders({success_resps, failed_resps}, syndicate, store_api) do
    {successfull_saves, failed_saves} =
      success_resps
      |> Enum.map(&get_order_id/1)
      |> Enum.map(&store_api.save_order(&1, syndicate))
      |> Enum.split_with(&status_ok?/1)

    {successfull_saves, failed_resps ++ failed_saves}
  end

  @spec list_orders(Manager.syndicate, deps :: module)
    :: Store.list_orders_response
  defp list_orders(syndicate, store), do: store.list_orders(syndicate)

  @spec make_delete_requests([Manager.order_id], deps :: module) ::
    {[{:ok, Manager.order_id}], [{:error, atom, Manager.order_id}]}
  defp make_delete_requests(order_ids, auction_house_api), do:
    order_ids
    |> Enum.map(&auction_house_api.delete_order/1)
    |> Enum.split_with(&status_ok?/1)

  @spec check_non_existent_orders(
    {[{:ok, Manager.order_id}], [{:error, atom, Manager.order_id}]}
  ) :: {[{:ok, Manager.order_id} | {:error, :order_non_existent, Manager.order_id}],
        [{:error, atom, Manager.order_id}]}
  defp check_non_existent_orders({success_resps, failed_resps}) do
    non_existent_orders =
      Enum.filter(failed_resps, &order_non_existent?/1)

    {success_resps ++ non_existent_orders, failed_resps}
  end

  @spec delete_orders(
    {[{:ok, Manager.order_id} | {:error, :order_non_existent, Manager.order_id}],
    [{:error, atom, Manager.order_id}]},
    Manager.syndicate,
    deps :: keyword
  ) :: {[{:ok, Manager.order_id}], [{:error, atom, Manager.order_id} | {:error, any}]}
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
    {:ok, Manager.order_id}
    | {:error, :order_non_existent, Manager.order_id}
  ) :: Manager.order_id
  defp get_order_id({:ok, order_id}), do: order_id
  defp get_order_id({:error, :order_non_existent, order_id}), do: order_id

  @spec order_non_existent?(any) :: boolean
  defp order_non_existent?({:error, :order_non_existent, _order_id}), do: true
  defp order_non_existent?(_), do: false

  @spec validate_login_info(Store.login_info) :: {:ok, Store.login_info} | {:error, {:missing_keys, [String.t]}}
  defp validate_login_info(info) do
    login_keys =
      info
      |> Map.keys()
      |> MapSet.new()

    obligatory_keys = MapSet.new(@mandatory_keys_login_info)
    missing_keys = MapSet.difference(obligatory_keys, login_keys)

    if Enum.empty?(missing_keys) do
      {:ok, info}
    else
      {:error, {:missing_keys, MapSet.to_list(missing_keys)}}
    end
  end

  @spec save_setup(Store.login_info, module) :: Store.setup_response
  defp save_setup(info, store), do: store.setup(info)

  @spec to_human_response({[any], [any]}, :delete | :place) ::
    {:ok, :success}
    | {
        :partial_success,
        [failed_orders: [{:error, Manager.error_reason, Manager.order_id | Manager.item_id}, ...]]
      }
    | {
        :error,
        :unable_to_place_requests,
        [{:error, Manager.error_reason, Manager.order_id | Manager.item_id}]
      }
    | {
        :error,
        :unable_to_delete_orders,
        [{:error, Manager.error_reason, Manager.order_id | Manager.item_id}]
      }
  defp to_human_response({successfull, failed}, :place) when successfull == [], do:
    {:error, :unable_to_place_requests, failed}

  defp to_human_response({successfull, failed}, :delete) when successfull == [], do:
    {:error, :unable_to_delete_orders, failed}

  defp to_human_response({_successfull, failed}, _op) when failed == [], do:
    {:ok, :success}

  defp to_human_response({_successfull, failed}, _op), do:
    {:partial_success, [failed_orders: failed]}

  @spec handle_setup_response({:ok, Store.login_info} | {:error, {:missing_keys, [String.t]} | :file.posix}, Store.login_info) ::
  {:ok, Store.login_info}
  | {:error, :unable_to_save_setup, {:missing_mandatory_keys, [String.t], Store.login_info} | {:file.posix, Store.login_info}}
  defp handle_setup_response({:error, {:missing_keys, keys}}, login_info), do:
    {:error, :unable_to_save_setup, {:missing_mandatory_keys, keys, login_info}}

  defp handle_setup_response({:error, reason}, login_info), do:
    {:error, :unable_to_save_setup, {reason, login_info}}

  defp handle_setup_response(ok_response, _login_info), do: ok_response
end
