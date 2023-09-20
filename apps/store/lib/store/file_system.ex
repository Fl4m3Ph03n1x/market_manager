defmodule Store.FileSystem do
  @moduledoc """
  Adapter for the Store port, implements it using the file system.
  """

  alias Shared.Data.{Authorization, PlacedOrder, Product, Syndicate, User}
  alias Shared.Utils.Tuples
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

  @spec list_products(Syndicate.t(), Type.dependencies()) :: Type.list_products_response()
  def list_products(syndicate, deps \\ @default_deps) do
    case read_syndicate_data(@products_filename, syndicate, deps) do
      {:ok, products} ->
        {:ok, Enum.map(products, &Product.new/1)}

      err ->
        err
    end
  end

  @spec list_orders(Syndicate.t(), Type.dependencies()) :: Type.list_orders_response()
  def list_orders(syndicate, deps \\ @default_deps) do
    case read_syndicate_data(@orders_filename, syndicate, deps) do
      {:ok, data} ->
        {:ok, Enum.map(data, &PlacedOrder.new/1)}

      err ->
        err
    end
  end

  @spec save_order(PlacedOrder.t(), Syndicate.t(), Type.dependencies()) ::
          Type.save_order_response()
  def save_order(placed_order, syndicate, deps \\ @default_deps) do
    with {:ok, content} <- read(@orders_filename, deps),
         {:ok, orders} <- decode_orders(content),
         {:ok, updated_orders} <- add_order(orders, placed_order, syndicate),
         {:ok, json} <- Jason.encode(updated_orders) do
      write(json, @orders_filename, deps)
    end
  end

  @spec delete_order(PlacedOrder.t(), Syndicate.t(), Type.dependencies()) ::
          Type.delete_order_response()
  def delete_order(placed_order, syndicate, deps \\ @default_deps) do
    with {:ok, content} <- read(@orders_filename, deps),
         {:ok, orders} <- decode_orders(content),
         {:ok, updated_orders} <- remove_order(orders, placed_order, syndicate),
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
          Syndicate.t(),
          Type.dependencies()
        ) ::
          {:ok, [map()]}
          | {:error, :file.posix() | Jason.DecodeError.t() | :syndicate_not_found}
  defp read_syndicate_data(filename, syndicate, file: file) do
    with {:ok, directory} <- file.cwd(),
         path <- Path.join(directory, filename),
         {:ok, content} <- file.read(path),
         {:ok, syndicates_data} <- Jason.decode(content) do
      find_syndicate(syndicates_data, syndicate)
    end
  end

  @spec find_syndicate(data :: map(), Syndicate.t()) ::
          {:ok, [map()]} | {:error, :syndicate_not_found}
  defp find_syndicate(data, syndicate) do
    case Map.get(data, Atom.to_string(syndicate.id), nil) do
      nil -> {:error, :syndicate_not_found}
      data -> {:ok, data}
    end
  end

  @spec decode_orders(content :: String.t()) ::
          {:ok, Type.all_orders_store() | %{}} | {:error, Jason.DecodeError.t()}
  defp decode_orders(""), do: {:ok, %{}}

  defp decode_orders(content) do
    case Jason.decode(content) do
      {:ok, decoded_content} ->
        decoded_content
        |> Enum.map(fn {syndicate, orders} ->
          {syndicate, Enum.map(orders, fn order -> PlacedOrder.new(order) end)}
        end)
        |> Map.new()
        |> Tuples.to_tagged_tuple()

      err ->
        err
    end
  end

  @spec add_order(Type.all_orders_store() | %{}, PlacedOrder.t(), Syndicate.t()) ::
          {:ok, Type.all_orders_store()}
  defp add_order(all_orders, placed_order, syndicate) do
    syndicate_id_str = Atom.to_string(syndicate.id)

    updated_syndicate_orders = Map.get(all_orders, syndicate_id_str, []) ++ [placed_order]
    {:ok, Map.put(all_orders, syndicate_id_str, updated_syndicate_orders)}
  end

  @spec remove_order(Type.all_orders_store() | %{}, PlacedOrder.t(), Syndicate.t()) ::
          {:ok, Type.all_orders_store()}
  defp remove_order(all_orders, placed_order, syndicate) do
    syndicate_id_str = Atom.to_string(syndicate.id)

    updated_syndicate_orders =
      all_orders
      |> Map.get(syndicate_id_str)
      |> List.delete(placed_order)

    {:ok, Map.put(all_orders, syndicate_id_str, updated_syndicate_orders)}
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
