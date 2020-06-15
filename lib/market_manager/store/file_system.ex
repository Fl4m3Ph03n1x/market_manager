defmodule MarketManager.Store.FileSystem do
  @moduledoc """
  Adapter for the Store port, implements it using the file system.
  """

  alias MarketManager.Store

  @behaviour Store

  @orders_filename Application.compile_env!(:market_manager, :current_orders)
  @products_filename Application.compile_env!(:market_manager, :products)

  ##########
  # Public #
  ##########

  @impl Store
  def get_products_from_syndicate(syndicate), do:
    @products_filename
    |> File.read!()
    |> Jason.decode!()
    |> find_syndicate(syndicate)

  @impl Store
  def list_orders(syndicate),
    do:
      @orders_filename
      |> File.read!()
      |> Jason.decode!()
      |> find_syndicate(syndicate)

  @impl Store
  def save_order(order_id, syndicate) do
    new_orders =
      @orders_filename
      |> File.read!()
      |> Jason.decode()
      |> get_orders()
      |> add_order(order_id, syndicate)
      |> Jason.encode!()

      case File.write(@orders_filename, new_orders) do
        :ok -> {:ok, order_id}
        err   -> err
      end
  end

  @impl Store
  def delete_order(order_id, syndicate) do
    new_orders =
      @orders_filename
      |> File.read!()
      |> Jason.decode()
      |> get_orders()
      |> delete_order(order_id, syndicate)
      |> Jason.encode!()

      case File.write(@orders_filename, new_orders) do
        :ok -> {:ok, order_id}
        err   -> err
      end
  end

  ###########
  # Private #
  ###########

  defp get_orders({:error, %Jason.DecodeError{data: ""}}), do: %{}
  defp get_orders({:ok, orders}), do: orders

  defp add_order(all_orders, order_id, syndicate), do:
    Map.put(all_orders, syndicate, Map.get(all_orders, syndicate, []) ++ [order_id])

  defp delete_order(all_orders, order_id, syndicate) do
    updated_syndicate_orders =
      all_orders
      |> Map.get(syndicate)
      |> List.delete(order_id)

    Map.put(all_orders, syndicate, updated_syndicate_orders)
  end

  defp find_syndicate(orders, syndicate) when is_map_key(orders, syndicate),
    do: {:ok, Map.get(orders, syndicate)}

  defp find_syndicate(_orders, syndicate), do: {:error, :syndicate_not_found, syndicate}
end
