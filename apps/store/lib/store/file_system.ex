defmodule Store.FileSystem do
  @moduledoc """
  Adapter for the Store port, implements it using the file system.
  """

  alias Shared.Data.{Authorization, User, Product}
  alias Store.Type

  @orders_filename Application.compile_env!(:store, :current_orders)
  @products_filename Application.compile_env!(:store, :products)
  @setup_filename Application.compile_env!(:store, :setup)

  @default_deps [
    file: File
  ]

  ##########
  # Public #
  ##########

  @spec list_products(Type.syndicate(), Type.dependencies()) :: Type.list_products_response()
  def list_products(syndicate, deps \\ @default_deps) do
    case read_syndicate_data(@products_filename, syndicate, deps) do
      {:ok, products} ->
        {:ok, Enum.map(products, &Product.new/1)}

      err ->
        err
    end
  end

  @spec list_orders(Type.syndicate(), Type.dependencies()) :: Type.list_orders_response()
  def list_orders(syndicate, deps \\ @default_deps),
    do: read_syndicate_data(@orders_filename, syndicate, deps)

  @spec save_order(Type.order_id(), Type.syndicate(), Type.dependencies()) ::
          Type.save_order_response()
  def save_order(order_id, syndicate, deps \\ @default_deps) do
    with {:ok, content} <- read(@orders_filename, deps),
         {:ok, orders} <- decode_orders(content),
         {:ok, updated_orders} <- add_order(orders, order_id, syndicate),
         {:ok, json} <- Jason.encode(updated_orders) do
      write(json, @orders_filename, deps)
    end
  end

  @spec delete_order(Type.order_id(), Type.syndicate(), Type.dependencies()) ::
          Type.delete_order_response()
  def delete_order(order_id, syndicate, deps \\ @default_deps) do
    with {:ok, content} <- read(@orders_filename, deps),
         {:ok, orders} <- decode_orders(content),
         {:ok, updated_orders} <- remove_order(orders, order_id, syndicate),
         {:ok, json} <- Jason.encode(updated_orders) do
      write(json, @orders_filename, deps)
    end
  end

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
         {:ok, decoded_data} <- Jason.decode(encoded_data) do
      decoded_auth = Map.get(decoded_data, "authorization")
      decoded_user = Map.get(decoded_data, "user")

      if valid_data?(decoded_auth, ["cookie", "token"]) and
           valid_data?(decoded_user, ["ingame_name", "patreon?"]) do
        {:ok, {Authorization.new(decoded_auth), User.new(decoded_user)}}
      else
        {:ok, nil}
      end
    end
  end

  @spec delete_login_data(Type.dependencies()) :: Type.delete_login_data_response()
  def delete_login_data(deps \\ @default_deps) do
    case Jason.encode(%{}) do
      {:ok, data} -> write(data, @setup_filename, deps)
      error -> error
    end
  end

  ###########
  # Private #
  ###########

  @spec read_syndicate_data(
          filename :: String.t(),
          Type.syndicate(),
          Type.dependencies()
        ) ::
          {:ok, [Type.order_id() | map()]}
          | {:error, :file.posix() | Jason.DecodeError.t() | :syndicate_not_found}
  defp read_syndicate_data(filename, syndicate, file: file) do
    with {:ok, directory} <- file.cwd(),
         path <- Path.join(directory, filename),
         {:ok, content} <- file.read(path),
         {:ok, syndicates_data} <- Jason.decode(content) do
      find_syndicate(syndicates_data, syndicate)
    end
  end

  @spec find_syndicate(data :: map(), Type.syndicate()) ::
          {:ok, [Type.order_id() | map()]} | {:error, :syndicate_not_found}
  defp find_syndicate(data, syndicate) when is_map_key(data, syndicate),
    do: {:ok, Map.get(data, syndicate)}

  defp find_syndicate(_data, _syndicate), do: {:error, :syndicate_not_found}

  @spec decode_orders(content :: String.t()) ::
          {:ok, map} | {:error, Jason.DecodeError.t()}
  defp decode_orders(""), do: {:ok, %{}}
  defp decode_orders(content), do: Jason.decode(content)

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

  @spec valid_data?(decoded_map :: map, fields :: [String.t()]) :: boolean()
  defp valid_data?(map, fields),
    do: not is_nil(map) and Enum.all?(fields, fn field -> not is_nil(Map.get(map, field)) end)

  @spec write(data :: String.t(), filename :: String.t(), Type.dependencies()) ::
          :ok | {:error, :file.posix()}
  defp write(data, filename, file: file) do
    case file.cwd() do
      {:ok, path} ->
        path
        |> Path.join(filename)
        |> file.write(data)

      error ->
        error
    end
  end

  @spec read(filename :: String.t(), Type.dependencies()) ::
          {:ok, String.t()} | {:error, :file.posix()}
  defp read(filename, file: file) do
    case file.cwd() do
      {:ok, path} ->
        path
        |> Path.join(filename)
        |> file.read()

      error ->
        error
    end
  end
end
