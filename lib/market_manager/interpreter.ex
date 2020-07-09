defmodule MarketManager.Interpreter do
  @moduledoc """
  Core of the market manager, where all the logic and communication with outer
  layers is. Currently, it works more like a bridge between the different ports
  of the application and manages data between them.
  """
  use Rop

  @default_deps [
    store: MarketManager.Store.FileSystem,
    auction_house: MarketManager.AuctionHouse.HTTPClient
  ]

  ##########
  # Public #
  ##########

  @spec activate(String.t, keyword) ::
          {:ok, :success}
          | {:partial_success, [{any, any}, ...]}
          | {:error, :unable_to_delete_orders | :unable_to_place_requests, [any]}
  def activate(syndicate, deps \\ @default_deps), do:
    syndicate
    |> list_products(deps[:store])
    >>> make_place_requests(deps[:auction_house])
    |> save_orders(syndicate, deps[:store])
    |> to_human_response(:place)

  @spec deactivate(String.t, keyword) ::
          {:ok, :success}
          | {:partial_success, [{any, any}, ...]}
          | {:error, :unable_to_delete_orders | :unable_to_place_requests, [any]}
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

  defp list_products(syndicate, store), do: store.list_products(syndicate)

  defp make_place_requests(products, auction_house_api), do:
    products
    |> Enum.map(&build_order/1)
    |> Enum.map(&auction_house_api.place_order/1)
    |> Enum.split_with(&status_ok?/1)

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

  defp save_orders({success_resps, failed_resps}, syndicate, store_api) do
    {successfull_saves, failed_saves} =
      success_resps
      |> Enum.map(&get_order_id/1)
      |> Enum.map(&store_api.save_order(&1, syndicate))
      |> Enum.split_with(&status_ok?/1)

    {successfull_saves, failed_resps ++ failed_saves}
  end

  defp list_orders(syndicate, store), do: store.list_orders(syndicate)

  defp make_delete_requests(order_ids, auction_house_api), do:
    order_ids
    |> Enum.map(&auction_house_api.delete_order/1)
    |> Enum.split_with(&status_ok?/1)

  defp check_non_existent_orders({success_resps, failed_resps}) do
    non_existent_orders =
      Enum.filter(failed_resps, &order_non_existent?/1)

    {success_resps ++ non_existent_orders, failed_resps}
  end

  defp delete_orders({success_resps, failed_resps}, syndicate, store_api) do
    {successfull_deletions, failed_deletions} =
      success_resps
      |> Enum.map(&get_order_id/1)
      |> Enum.map(&store_api.delete_order(&1, syndicate))
      |> Enum.split_with(&status_ok?/1)

    {successfull_deletions, failed_resps ++ failed_deletions}
  end

  defp status_ok?({:ok, _data}), do: true
  defp status_ok?(_order), do: false

  defp get_order_id({:ok, order_id}), do: order_id
  defp get_order_id({:error, :order_non_existent, order_id}), do: order_id

  @spec order_non_existent?(any) :: boolean
  defp order_non_existent?({:error, :order_non_existent, _order_id}), do: true
  defp order_non_existent?(_), do: false

  defp to_human_response({successfull, failed}, :place) when successfull == [], do:
    {:error, :unable_to_place_requests, failed}

  defp to_human_response({successfull, failed}, :delete) when successfull == [], do:
    {:error, :unable_to_delete_orders, failed}

  defp to_human_response({successfull, failed}, _op) when successfull == [], do:
    {:error, :unable_to_place_requests, failed}

  defp to_human_response({_successfull, failed}, _op) when failed == [], do:
    {:ok, :success}

  defp to_human_response({_successfull, failed}, _op), do:
    {:partial_success, [failed_orders: failed]}
end
