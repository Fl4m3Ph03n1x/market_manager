defmodule MarketManager.Store.FileSystem do
  @moduledoc """
  Adapter for the Store port, implements it using the file system.
  """

  use Rop

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
  def list_products(syndicate, deps \\ @default_deps), do:
    read_syndicate_data(@products_filename, syndicate, deps[:read_fn])

  @impl Store
  def list_orders(syndicate, deps \\ @default_deps), do:
    read_syndicate_data(@orders_filename, syndicate, deps[:read_fn])

  @impl Store
  def save_order(order_id, syndicate, deps \\ @default_deps), do:
    deps[:read_fn].(@orders_filename)
    >>> decode_orders_or_empty_orders()
    >>> add_order(order_id, syndicate)
    >>> Jason.encode()
    >>> save_new_orders(deps[:write_fn])
    >>> send_ok_response(order_id)

  @impl Store
  def delete_order(order_id, syndicate, deps \\ @default_deps), do:
    deps[:read_fn].(@orders_filename)
    >>> decode_orders_or_empty_orders()
    >>> remove_order(order_id, syndicate)
    >>> Jason.encode()
    >>> save_new_orders(deps[:write_fn])
    >>> send_ok_response(order_id)

  ###########
  # Private #
  ###########

  @spec read_syndicate_data(
      filename :: String.t, syndicate :: String.t, file_read_fn :: function
    ) ::
        {:ok, [Store.order_id | map]}
        | {:error, :syndicate_not_found, syndicate_name :: String.t}
        | {:error, any}
  defp read_syndicate_data(filename, syndicate, read_fn), do:
    read_fn.(filename)
    >>> Jason.decode()
    >>> find_syndicate(syndicate)

  defp find_syndicate(orders, syndicate) when is_map_key(orders, syndicate), do:
    {:ok, Map.get(orders, syndicate)}

  defp find_syndicate(_orders, syndicate), do:
    {:error, :syndicate_not_found, syndicate}

  defp decode_orders_or_empty_orders(""), do: {:ok, %{}}
  defp decode_orders_or_empty_orders(content), do: Jason.decode(content)

  defp add_order(all_orders, order_id, syndicate), do:
    {:ok, Map.put(all_orders, syndicate, Map.get(all_orders, syndicate, []) ++ [order_id])}

  defp remove_order(all_orders, order_id, syndicate) do
    updated_syndicate_orders =
      all_orders
      |> Map.get(syndicate)
      |> List.delete(order_id)

    {:ok, Map.put(all_orders, syndicate, updated_syndicate_orders)}
  end

  defp save_new_orders(orders, write_fn) do
    case write_fn.(@orders_filename, orders) do
      :ok -> {:ok, :new_orders_saved}
      err -> err
    end
  end

  defp send_ok_response(:new_orders_saved, order_id), do: {:ok, order_id}
end
