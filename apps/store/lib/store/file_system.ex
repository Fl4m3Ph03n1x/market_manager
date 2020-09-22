defmodule Store.FileSystem do
  @moduledoc """
  Adapter for the Store port, implements it using the file system.
  """

  use Rop

  @behaviour Store

  @orders_filename Application.compile_env!(:store, :current_orders)
  @products_filename Application.compile_env!(:store, :products)

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

  def syndicate_exists?(syndicate, deps \\ @default_deps) do
    case read_syndicate_data(@products_filename, syndicate, deps[:read_fn]) do
      {:ok, _data} -> true
      _ -> false
    end
  end

  ###########
  # Private #
  ###########

  @spec read_syndicate_data(
      filename :: String.t, Store.syndicate, file_read_fn :: function
    ) :: {:ok, [Store.order_id | [Store.product]]} | {:error, any}
  defp read_syndicate_data(filename, syndicate, read_fn), do:
    read_fn.(filename)
    >>> Jason.decode()
    >>> find_syndicate(syndicate)

  @spec find_syndicate(Store.all_orders_store, Store.syndicate) ::
    {:ok, [Store.order_id] | [Store.product]} | {:error, :syndicate_not_found}
  defp find_syndicate(orders, syndicate) when is_map_key(orders, syndicate), do:
    {:ok, Map.get(orders, syndicate)}

  defp find_syndicate(_orders, _syndicate), do: {:error, :syndicate_not_found}

  @spec decode_orders_or_empty_orders(content :: String.t)
    :: {:ok, map} | {:error, any}
  defp decode_orders_or_empty_orders(""), do: {:ok, %{}}
  defp decode_orders_or_empty_orders(content), do: Jason.decode(content)

  @spec add_order(Store.all_orders_store, Store.order_id, Store.syndicate)
    :: {:ok, Store.all_orders_store}
  defp add_order(all_orders, order_id, syndicate), do:
    {:ok, Map.put(all_orders, syndicate, Map.get(all_orders, syndicate, []) ++ [order_id])}

  @spec remove_order(Store.all_orders_store, Store.order_id, Store.syndicate)
    :: {:ok, Store.all_orders_store}
  defp remove_order(all_orders, order_id, syndicate) do
    updated_syndicate_orders =
      all_orders
      |> Map.get(syndicate)
      |> List.delete(order_id)

    {:ok, Map.put(all_orders, syndicate, updated_syndicate_orders)}
  end

  @spec save_new_orders(orders_json :: String.t, file_write_fn :: function) ::
    {:ok, :new_orders_saved}
    | {:error, any}
  defp save_new_orders(orders, write_fn) do
    case write_fn.(@orders_filename, orders) do
      :ok -> {:ok, :new_orders_saved}
      err -> err
    end
  end

  @spec send_ok_response(:new_orders_saved, Store.order_id) :: {:ok, Store.order_id}
  defp send_ok_response(:new_orders_saved, order_id), do: {:ok, order_id}
end
