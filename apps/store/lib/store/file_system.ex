defmodule Store.FileSystem do
  @moduledoc """
  Adapter for the Store port, implements it using the file system.
  """

  require Config
  alias Shared.Data.{Authorization, PlacedOrder, Product, Syndicate, User}
  alias Shared.Utils.Tuples
  alias Store.Type

  @default_deps %{
    file: File,
    paths: [
      current_orders: Application.compile_env!(:store, :current_orders),
      products: Application.compile_env!(:store, :products),
      syndicates: Application.compile_env!(:store, :syndicates),
      setup: Application.compile_env!(:store, :setup)
    ],
    env: Application.compile_env!(:store, :env)
  }

  ##########
  # Public #
  ##########

  @spec list_products(Syndicate.t(), Type.dependencies()) :: Type.list_products_response()
  def list_products(syndicate, deps \\ @default_deps) do
    %{paths: paths, env: env} = Map.merge(@default_deps, deps)

    with {:ok, path} <- build_absolute_path(paths[:products], env),
         {:ok, products} <- read_syndicate_data(path, syndicate, deps) do
      {:ok, Enum.map(products, &Product.new/1)}
    end
  end

  @spec list_orders(Syndicate.t(), Type.dependencies()) :: Type.list_orders_response()
  def list_orders(syndicate, deps \\ @default_deps) do
    %{paths: paths, env: env} = Map.merge(@default_deps, deps)

    with {:ok, path} <- build_absolute_path(paths[:current_orders], env),
         {:ok, data} <- read_syndicate_data(path, syndicate, deps) do
      {:ok, Enum.map(data, &PlacedOrder.new/1)}
    end
  end

  @spec save_order(PlacedOrder.t(), Syndicate.t(), Type.dependencies()) ::
          Type.save_order_response()
  def save_order(placed_order, syndicate, deps \\ @default_deps) do
    %{file: file, paths: paths, env: env} = Map.merge(@default_deps, deps)

    with {:ok, path} <- build_absolute_path(paths[:current_orders], env),
         {:ok, content} <- file.read(path),
         {:ok, orders} <- decode_orders(content),
         {:ok, updated_orders} <- add_order(orders, placed_order, syndicate),
         {:ok, json} <- Jason.encode(updated_orders) do
      file.write(path, json)
    end
  end

  @spec delete_order(PlacedOrder.t(), Syndicate.t(), Type.dependencies()) ::
          Type.delete_order_response()
  def delete_order(placed_order, syndicate, deps \\ @default_deps) do
    %{file: file, paths: paths, env: env} = Map.merge(@default_deps, deps)

    with {:ok, path} <- build_absolute_path(paths[:current_orders], env),
         {:ok, content} <- file.read(path),
         {:ok, orders} <- decode_orders(content),
         {:ok, updated_orders} <- remove_order(orders, placed_order, syndicate),
         {:ok, json} <- Jason.encode(updated_orders) do
      file.write(path, json)
    end
  end

  @spec save_login_data(Authorization.t(), User.t(), Type.dependencies()) ::
          Type.save_login_data_response()
  def save_login_data(auth, user, deps \\ @default_deps) do
    %{file: file, paths: paths, env: env} = Map.merge(@default_deps, deps)

    with {:ok, path} <- build_absolute_path(paths[:setup], env),
         {:ok, data} <- Jason.encode(%{authorization: auth, user: user}) do
      file.write(path, data)
    end
  end

  @spec get_login_data(Type.dependencies()) :: Type.get_login_data_response()
  def get_login_data(deps \\ @default_deps) do
    %{file: file, paths: paths, env: env} = Map.merge(@default_deps, deps)

    with {:ok, path} <- build_absolute_path(paths[:setup], env),
         {:ok, encoded_data} <- file.read(path),
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
    %{file: file, paths: paths, env: env} = Map.merge(@default_deps, deps)

    with {:ok, data} <- Jason.encode(%{}),
         {:ok, path} <- build_absolute_path(paths[:setup], env) do
      file.write(path, data)
    end
  end

  @spec list_syndicates(Type.dependencies()) :: Type.list_syndicates_response()
  def list_syndicates(deps \\ @default_deps) do
    %{file: file, paths: paths, env: env} = Map.merge(@default_deps, deps)

    with {:ok, path} <- build_absolute_path(paths[:syndicates], env),
         {:ok, content} <- file.read(path),
         {:ok, syndicates_data} <- Jason.decode(content) do
      {:ok, Enum.map(syndicates_data, &Syndicate.new/1)}
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
  defp read_syndicate_data(filename, syndicate, %{file: file}) do
    with {:ok, content} <- file.read(filename),
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

  @spec build_absolute_path([String.t()], atom()) ::
          {:ok, String.t()} | {:error, :cannot_detect_store_application}
  defp build_absolute_path(path, :prod) do
    case Application.get_application(__MODULE__) do
      nil -> {:error, :cannot_detect_store_application}
      app -> {:ok, Application.app_dir(app, path)}
    end
  end

  defp build_absolute_path(path, _env), do: {:ok, Path.join(path)}
end
