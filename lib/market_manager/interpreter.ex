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

  def activate(syndicate, deps \\ @default_deps) do
    store_api = deps[:store]
    auction_house_api = deps[:auction_house]

    with {:ok, syndicate_products} <- store_api.list_products(syndicate),
         {success_resps, failed_resps} <- make_requests(auction_house_api, syndicate_products) do
      success_resps
      |> Enum.map(fn {:ok, order_id} -> order_id end)
      |> Enum.each(&store_api.save_order(&1, syndicate))

      if Enum.empty?(success_resps) do
        {:error, :unable_to_place_requests, failed_resps}
      else
        case Enum.empty?(failed_resps) do
          true -> {:ok, :success}
          false -> {:partial_success, [failed_orders: failed_resps]}
        end
      end
    end

    # syndicate
    # |> list_products(store_api)
    # >>> make_place_requests(auction_house_api)
    # |> save_orders()
    # |> to_human_response()

  end

  # defp list_products(syndicate, store), do: store.list_products(syndicate)

  # defp save_orders({success_resps, failed_resps}) do
  #   # this can fail, so if it fails, we pass it to failed_resps
  #   success_resps
  #   |> Enum.map(fn {:ok, order_id} -> order_id end)
  #   |> Enum.each(&store_api.save_order(&1, syndicate))

  #   {success_resps, failed_resps}
  # end

  # defp to_human_response({successfull, failed}) when successfull == [], do:
  #   {:error, :unable_to_place_requests, failed}

  # defp to_human_response({_successfull, failed}) when failed == [], do:
  #   {:ok, :success}

  # defp to_human_response({_successfull, failed}), do:
  #   {:partial_success, [failed_orders: failed]}

  def deactivate(syndicate, deps \\ @default_deps) do
    store_api = deps[:store]
    auction_house_api = deps[:auction_house]

    with {:ok, orders} <- store_api.list_orders(syndicate),
         {success_resps, failed_resps} <- make_delete_requests(auction_house_api, orders) do
      success_resps = Enum.map(success_resps, &get_order_id/1)

      non_existent_orders =
        failed_resps
        |> Enum.filter(&order_non_existent?/1)
        |> Enum.map(&get_order_id/1)

      Enum.each(
        success_resps ++ non_existent_orders,
        &store_api.delete_order(&1, syndicate)
      )

      if Enum.empty?(success_resps) do
        {:error, :unable_to_delete_orders, failed_resps}
      else
        case Enum.empty?(failed_resps) do
          true -> {:ok, :success}
          false -> {:partial_success, [failed_orders: failed_resps]}
        end
      end
    end
  end

  ###########
  # Private #
  ###########

  defp make_requests(auction_house_api, products),
    do:
      products
      |> Enum.map(&build_order/1)
      |> Enum.map(&auction_house_api.place_order/1)
      |> Enum.split_with(&request_successful?/1)

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

  defp make_delete_requests(auction_house_api, order_ids),
    do:
      order_ids
      |> Enum.map(&auction_house_api.delete_order/1)
      |> Enum.split_with(&request_successful?/1)

  defp request_successful?({:ok, _data}), do: true
  defp request_successful?(_order), do: false

  defp get_order_id({:ok, order_id}), do: order_id
  defp get_order_id({:error, :order_non_existent, order_id}), do: order_id

  @spec order_non_existent?(any) :: boolean
  defp order_non_existent?({:error, :order_non_existent, _order_id}), do: true
  defp order_non_existent?(_), do: false
end
