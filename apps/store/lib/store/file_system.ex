defmodule Store.FileSystem do
  @moduledoc """
  Adapter for the Store port, implements it using the file system.
  """

  use Rop

  alias Store

  @orders_filename Application.compile_env!(:store, :current_orders)
  @products_filename Application.compile_env!(:store, :products)
  @setup_filename Application.compile_env!(:store, :setup)

  @default_deps [
    read_fn: &File.read/1,
    write_fn: &File.write/2
  ]

  ##########
  # Public #
  ##########

  @spec list_products(Store.syndicate) :: Store.list_products_response
  def list_products(syndicate, deps \\ @default_deps), do:
    read_syndicate_data(@products_filename, syndicate, deps[:read_fn])

  @spec list_orders(Store.syndicate) :: Store.list_orders_response
  def list_orders(syndicate, deps \\ @default_deps), do:
    read_syndicate_data(@orders_filename, syndicate, deps[:read_fn])

  @spec save_order(Store.order_id, Store.syndicate) :: Store.save_order_response
  def save_order(order_id, syndicate, deps \\ @default_deps), do:
    deps[:read_fn].(@orders_filename)
    >>> decode_orders_or_empty_orders()
    >>> add_order(order_id, syndicate)
    >>> Jason.encode()
    >>> save_new_orders(deps[:write_fn])
    >>> send_ok_response(order_id)

  @spec delete_order(Store.order_id, Store.syndicate) :: Store.delete_order_response
  def delete_order(order_id, syndicate, deps \\ @default_deps), do:
    deps[:read_fn].(@orders_filename)
    >>> decode_orders_or_empty_orders()
    >>> remove_order(order_id, syndicate)
    >>> Jason.encode()
    >>> save_new_orders(deps[:write_fn])
    >>> send_ok_response(order_id)

  @spec syndicate_exists?(Store.syndicate) :: Store.syndicate_exists_response
  def syndicate_exists?(syndicate, deps \\ @default_deps), do:
    @products_filename
    |> read_syndicate_data(syndicate, deps[:read_fn])
    |> syndicate_found?()

  @spec setup(Store.login_info) :: Store.setup_response
  def setup(login_info, deps \\ @default_deps), do:
    login_info
    |> Jason.encode()
    >>> save_setup(@setup_filename, deps)
    |> handle_setup_response(login_info)

  ###########
  # Private #
  ###########

  @spec read_syndicate_data(
      filename :: String.t, Store.syndicate, file_read_fn :: function
    ) :: {:ok, [Store.order_id | [Store.product]]} | {:error, any}
  defp read_syndicate_data(filename, syndicate, read_fn), do:
    "../../#{filename}"
    |> Path.expand(__DIR__)
    |> read_fn.()
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
    case write_fn.(Path.expand("../../#{@orders_filename}", __DIR__), orders) do
      :ok -> {:ok, :new_orders_saved}
      err -> err
    end
  end

  @spec syndicate_found?({:error, any} | {:ok, map}) :: {:ok, boolean} | {:error, any}
  defp syndicate_found?({:error, :syndicate_not_found}), do: {:ok, false}
  defp syndicate_found?({:ok, _data}), do: {:ok, true}
  defp syndicate_found?({:error, _reason} = error), do: error

  @spec send_ok_response(:new_orders_saved, Store.order_id) :: {:ok, Store.order_id}
  defp send_ok_response(:new_orders_saved, order_id), do: {:ok, order_id}

  @spec save_setup(String.t, String.t, Store.deps) :: :ok | {:error, :file.posix}
  defp save_setup(data, filename, deps), do:
    deps[:write_fn].(filename, data)

  @spec handle_setup_response(:ok | {:error, :file.posix}, Store.login_info) :: {:ok, Store.login_info} | {:error, :file.posix}
  defp handle_setup_response(:ok, login_info), do: {:ok, login_info}
  defp handle_setup_response(err, _login_info), do: err

end
