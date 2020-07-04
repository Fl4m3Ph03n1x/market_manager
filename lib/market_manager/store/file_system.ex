defmodule MarketManager.Store.FileSystem do
  @moduledoc """
  Adapter for the Store port, implements it using the file system.
  """

  alias MarketManager.Store

  @behaviour Store

  @orders_filename Application.compile_env!(:market_manager, :current_orders)
  @products_filename Application.compile_env!(:market_manager, :products)

  @default_deps [
    read_fn: &File.read/1,
    write_fn: &File.write/2
  ]

  ##########
  # Public #
  ##########

  @impl Store
  def list_products(syndicate, deps \\ @default_deps) do
    read = deps[:read_fn]

    with {:ok, content} <- read.(@products_filename),
         {:ok, products} <- Jason.decode(content) do
      find_syndicate(products, syndicate)
    end
  end

  @impl Store
  def list_orders(syndicate, deps \\ @default_deps) do
    read = deps[:read_fn]

    with {:ok, content} <- read.(@orders_filename),
         {:ok, orders} <- Jason.decode(content) do
      find_syndicate(orders, syndicate)
    end
  end

  @impl Store
  def save_order(order_id, syndicate, deps \\ @default_deps) do
    read = deps[:read_fn]
    write = deps[:write_fn]

    with {:ok, content} <- read.(@orders_filename),
         maybe_decode <- Jason.decode(content),
         orders <- get_orders(maybe_decode),
         new_orders <- add_order(orders, order_id, syndicate),
         {:ok, new_content} <- Jason.encode(new_orders),
         :ok <- write.(@orders_filename, new_content) do
      {:ok, order_id}
    end
  end

  @impl Store
  def delete_order(order_id, syndicate, deps \\ @default_deps) do
    read = deps[:read_fn]
    write = deps[:write_fn]

    with {:ok, content} <- read.(@orders_filename),
         maybe_decode <- Jason.decode(content),
         orders <- get_orders(maybe_decode),
         new_orders <- remove_order(orders, order_id, syndicate),
         {:ok, new_content} <- Jason.encode(new_orders),
         :ok <- write.(@orders_filename, new_content) do
      {:ok, order_id}
    end

    # new_orders =
    #   @orders_filename
    #   |> File.read!()
    #   |> Jason.decode()
    #   |> get_orders()
    #   |> remove_order(order_id, syndicate)
    #   |> Jason.encode!()

    # case File.write(@orders_filename, new_orders) do
    #   :ok -> {:ok, order_id}
    #   err -> err
    # end
  end

  ###########
  # Private #
  ###########

  defp get_orders({:error, %Jason.DecodeError{data: ""}}), do: %{}
  defp get_orders({:ok, orders}), do: orders

  defp add_order(all_orders, order_id, syndicate),
    do: Map.put(all_orders, syndicate, Map.get(all_orders, syndicate, []) ++ [order_id])

  defp remove_order(all_orders, order_id, syndicate) do
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
