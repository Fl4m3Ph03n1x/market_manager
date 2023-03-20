defmodule Store.FileSystem do
  @moduledoc """
  Adapter for the Store port, implements it using the file system.
  """

  use Rop

  alias Shared.Data.{Authorization, User}
  alias Store.Type

  @orders_filename Application.compile_env!(:store, :current_orders)
  @products_filename Application.compile_env!(:store, :products)
  @setup_filename Application.compile_env!(:store, :setup)

  @default_deps [
    read_fn: &File.read/1,
    write_fn: &File.write/2,
    current_working_directory: &File.cwd/0
  ]

  ##########
  # Public #
  ##########

  @spec list_products(Type.syndicate(), Type.dependencies()) :: Type.list_products_response()
  def list_products(syndicate, deps \\ @default_deps),
    do: read_syndicate_data(@products_filename, syndicate, deps[:read_fn])

  @spec list_orders(Type.syndicate(), Type.dependencies()) :: Type.list_orders_response()
  def list_orders(syndicate, deps \\ @default_deps),
    do: read_syndicate_data(@orders_filename, syndicate, deps[:read_fn])

  @spec save_order(Type.order_id(), Type.syndicate(), Type.dependencies()) ::
          Type.save_order_response()
  def save_order(order_id, syndicate, deps \\ @default_deps),
    do:
      deps[:read_fn].(@orders_filename) >>>
        decode_orders_or_empty_orders() >>>
        add_order(order_id, syndicate) >>>
        Jason.encode() >>>
        write(@orders_filename, deps) >>>
        send_ok_response(order_id)

  @spec delete_order(Type.order_id(), Type.syndicate(), Type.dependencies()) ::
          Type.delete_order_response()
  def delete_order(order_id, syndicate, deps \\ @default_deps),
    do:
      deps[:read_fn].(@orders_filename) >>>
        decode_orders_or_empty_orders() >>>
        remove_order(order_id, syndicate) >>>
        Jason.encode() >>>
        write(@orders_filename, deps) >>>
        send_ok_response(order_id)

  @spec save_login_data(Authorization.t(), User.t(), Type.dependencies()) ::
          Type.save_login_data_response()
  def save_login_data(auth, user, deps \\ @default_deps) do
    case Jason.encode(%{authorization: auth, user: user}) do
      {:ok, data} -> write(data, @setup_filename, deps)
      error -> error
    end
  end

  @spec get_login_data(Type.dependencies()) :: Type.get_login_data_response()
  def get_login_data(deps \\ @default_deps) do
    with {:ok, encoded_data} <- read(@setup_filename, deps),
         {:ok, %{"authorization" => decoded_auth, "user" => decoded_user}} <-
           Jason.decode(encoded_data) do
      if is_nil(decoded_auth) or is_nil(decoded_user) do
        {:ok, nil}
      else
        {:ok, {Authorization.new(decoded_auth), User.new(decoded_user)}}
      end
    end
  end

  @spec delete_login_data(Type.dependencies()) :: Type.delete_login_data_response()
  def delete_login_data(deps \\ @default_deps) do
    nil
  end

  ###########
  # Private #
  ###########

  @spec read_syndicate_data(
          filename :: String.t(),
          Type.syndicate(),
          file_read_fn :: function
        ) :: {:ok, [Type.order_id() | [Type.product()]]} | {:error, any}
  defp read_syndicate_data(filename, syndicate, read_fn) do
    File.cwd!()
    |> Path.join(filename)
    |> read_fn.() >>>
      Jason.decode() >>>
      find_syndicate(syndicate)
  end

  @spec find_syndicate(Type.all_orders_store(), Type.syndicate()) ::
          {:ok, [Type.order_id()] | [Type.product()]} | {:error, :syndicate_not_found}
  defp find_syndicate(orders, syndicate) when is_map_key(orders, syndicate),
    do: {:ok, Map.get(orders, syndicate)}

  defp find_syndicate(_orders, _syndicate), do: {:error, :syndicate_not_found}

  @spec decode_orders_or_empty_orders(content :: String.t()) ::
          {:ok, map} | {:error, any}
  defp decode_orders_or_empty_orders(""), do: {:ok, %{}}
  defp decode_orders_or_empty_orders(content), do: Jason.decode(content)

  @spec add_order(Type.all_orders_store(), Type.order_id(), Type.syndicate()) ::
          {:ok, Type.all_orders_store()}
  defp add_order(all_orders, order_id, syndicate),
    do: {:ok, Map.put(all_orders, syndicate, Map.get(all_orders, syndicate, []) ++ [order_id])}

  @spec remove_order(Type.all_orders_store(), Type.order_id(), Type.syndicate()) ::
          {:ok, Type.all_orders_store()}
  defp remove_order(all_orders, order_id, syndicate) do
    updated_syndicate_orders =
      all_orders
      |> Map.get(syndicate)
      |> List.delete(order_id)

    {:ok, Map.put(all_orders, syndicate, updated_syndicate_orders)}
  end

  @spec send_ok_response(saved_data :: any, response_data :: any) :: {:ok, response_data :: any}
  defp send_ok_response(_saved_data, response_data), do: {:ok, response_data}

  @spec write(data :: String.t(), filename :: String.t(), Type.dependencies()) ::
          :ok | {:error, :file.posix()}
  defp write(data, filename, deps) do
    case deps[:current_working_directory].() do
      {:ok, path} ->
        path
        |> Path.join(filename)
        |> deps[:write_fn].(data)

      error ->
        error
    end
  end

  @spec read(filename :: String.t(), Type.dependencies()) ::
          {:ok, String.t()} | {:error, :file.posix()}
  defp read(filename, deps) do
    case deps[:current_working_directory].() do
      {:ok, path} ->
        path
        |> Path.join(filename)
        |> deps[:read_fn].()

      error ->
        error
    end
  end
end
