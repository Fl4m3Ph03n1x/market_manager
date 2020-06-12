defmodule MarketManager.Implementation do
  @moduledoc """
  """

  @auction_house_api Application.compile_env!(:market_manager, :auction_house_api)
  @store_api Application.compile_env!(:market_manager, :store_api)

  ##########
  # Public #
  ##########

  def activate(syndicate) do
    with {:ok, syndicate_products} <- @store_api.get_products_from_syndicate(syndicate),
         {success_resps, failed_resps} <- make_requests(syndicate_products) do
      success_resps
      |> Enum.map(fn {:ok, order_id} -> order_id end)
      |> Enum.each(&@store_api.save_order(&1, syndicate))

      if Enum.empty?(success_resps) do
        {:error, :unable_to_place_requests, failed_resps}
      else
        case Enum.empty?(failed_resps) do
          true -> {:ok, :success}
          false -> {:partial_success, [failed_orders: failed_resps]}
        end
      end
    end
  end

  def deactivate(syndicate) do
    with {:ok, orders} <- @store_api.list_orders(syndicate),
         {success_resps, failed_resps} <- make_delete_requests(orders) do

      success_resps = Enum.map(success_resps, &get_order_id/1)

      non_existent_orders =
        failed_resps
        |> Enum.filter(&order_non_existent?/1)
        |> Enum.map(&get_order_id/1)

      Enum.each(
        success_resps ++ non_existent_orders,
        &@store_api.delete_order(&1, syndicate)
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

  defp make_requests(products),
    do:
      products
      |> Enum.map(&build_order/1)
      |> Enum.map(&@auction_house_api.place_order/1)
      |> Enum.split_with(&request_successful?/1)

  defp build_order(product),
    do: %{
      "order_type" => "sell",
      "item_id" => Map.get(product, "id"),
      "platinum" => Map.get(product, "price"),
      "quantity" => Map.get(product, "quantity", 1),
      "mod_rank" => Map.get(product, "rank", 0)
    }

  defp make_delete_requests(order_ids),
    do:
      order_ids
      |> Enum.map(&@auction_house_api.delete_order/1)
      |> Enum.split_with(&request_successful?/1)

  defp request_successful?({:ok, _data}), do: true
  defp request_successful?(_order), do: false

  defp get_order_id({:ok, order_id}), do: order_id
  defp get_order_id({:error, :order_non_existent, order_id}), do: order_id

  defp order_non_existent?({:error, :order_non_existent, _order_id}), do: true
  defp order_non_existent?(_), do: false

end
