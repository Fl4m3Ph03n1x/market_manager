defmodule Store.FileSystem do
  @moduledoc """
  Adapter for the Store port, implements it using the file system.
  """

  require Config
  alias Shared.Data.{Authorization, Product, Strategy, Syndicate, User}
  alias Shared.Utils.{Maps, Tuples}
  alias Store.Type

  @typep filename :: String.t()

  @default_deps %{
    io: %{
      read: &File.read/1,
      write: &File.write/2
    },
    paths: [
      watch_list: Application.compile_env!(:store, :watch_list),
      products: Application.compile_env!(:store, :products),
      syndicates: Application.compile_env!(:store, :syndicates),
      setup: Application.compile_env!(:store, :setup)
    ],
    env: Application.compile_env!(:store, :env)
  }

  ##########
  # Public #
  ##########

  @spec list_products([Syndicate.id()], Type.dependencies()) :: Type.list_products_response()
  def list_products(syndicate_ids, deps \\ @default_deps) do
    %{paths: paths, env: env} = deps = Map.merge(@default_deps, deps)

    with {:ok, syndicates_path} <- build_absolute_path(paths[:syndicates], env),
         {:ok, products_path} <- build_absolute_path(paths[:products], env),
         {:ok, products} <- read_product_data(products_path, deps),
         {:ok, syndicates} <- read_syndicate_data(syndicates_path, deps) do
      syndicate_ids_set = MapSet.new(syndicate_ids)
      all_syndicate_ids_set = syndicates |> Enum.map(& &1.id) |> MapSet.new()

      all_valid_syndicate_ids? =
        MapSet.union(syndicate_ids_set, all_syndicate_ids_set)
        |> MapSet.equal?(all_syndicate_ids_set)

      if all_valid_syndicate_ids? do
        syndicate_catalogs =
          syndicates
          |> Enum.filter(&(&1.id in syndicate_ids))
          |> Enum.flat_map(& &1.catalog)

        products
        |> Enum.filter(&Enum.member?(syndicate_catalogs, &1.id))
        |> Tuples.to_tagged_tuple()
      else
        not_found =
          syndicate_ids_set
          |> MapSet.reject(fn id -> MapSet.member?(all_syndicate_ids_set, id) end)
          |> MapSet.to_list()

        {:error, {:syndicate_not_found, not_found}}
      end
    end
  end

  @spec get_product_by_id(Product.id(), Type.dependencies()) :: Type.get_product_by_id_response()
  def get_product_by_id(id, deps \\ @default_deps) do
    %{paths: paths, env: env} = deps = Map.merge(@default_deps, deps)

    with {:ok, path} <- build_absolute_path(paths[:products], env),
         {:ok, products} <- read_product_data(path, deps) do
      case Enum.find(products, &(&1.id == id)) do
        nil -> {:error, :product_not_found}
        product -> {:ok, product}
      end
    end
  end

  @spec save_login_data(Authorization.t(), User.t(), Type.dependencies()) ::
          Type.save_login_data_response()
  def save_login_data(auth, user, deps \\ @default_deps) do
    %{io: io, paths: paths, env: env} = Map.merge(@default_deps, deps)

    with {:ok, path} <- build_absolute_path(paths[:setup], env),
         {:ok, data} <- Jason.encode(%{authorization: auth, user: user}) do
      io.write.(path, data)
    end
  end

  @spec get_login_data(Type.dependencies()) :: Type.get_login_data_response()
  def get_login_data(deps \\ @default_deps) do
    %{io: io, paths: paths, env: env} = Map.merge(@default_deps, deps)

    with {:ok, path} <- build_absolute_path(paths[:setup], env),
         {:ok, encoded_data} <- io.read.(path),
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
    %{io: io, paths: paths, env: env} = Map.merge(@default_deps, deps)

    with {:ok, data} <- Jason.encode(%{}),
         {:ok, path} <- build_absolute_path(paths[:setup], env) do
      io.write.(path, data)
    end
  end

  @spec list_syndicates(Type.dependencies()) :: Type.list_syndicates_response()
  def list_syndicates(deps \\ @default_deps) do
    %{io: io, paths: paths, env: env} = Map.merge(@default_deps, deps)

    with {:ok, path} <- build_absolute_path(paths[:syndicates], env),
         {:ok, content} <- io.read.(path),
         {:ok, syndicates_data} <- Jason.decode(content) do
      {:ok, Enum.map(syndicates_data, &Syndicate.new/1)}
    end
  end

  @spec activate_syndicates(%{Syndicate.id() => Strategy.id()}, Type.dependencies()) ::
          Type.activate_syndicates_response()
  def activate_syndicates(syndicates_with_strategy, deps \\ @default_deps)
      when syndicates_with_strategy != %{} do
    %{io: io, paths: paths, env: env} = Map.merge(@default_deps, deps)

    with {:ok, watch_list_path} <- build_absolute_path(paths[:watch_list], env),
         {:ok, content} <- io.read.(watch_list_path),
         {:ok, watch_list} <- Jason.decode(content),
         updated_active_syndicates <-
           watch_list
           |> Map.get("active_syndicates", %{})
           |> Map.merge(syndicates_with_strategy),
         {:ok, encoded_content} <-
           watch_list
           |> Map.put("active_syndicates", updated_active_syndicates)
           |> Jason.encode() do
      io.write.(watch_list_path, encoded_content)
    end
  end

  @spec deactivate_syndicates([Syndicate.id()], Type.dependencies()) ::
          Type.deactivate_syndicates_response()
  def deactivate_syndicates(syndicates, deps \\ @default_deps) when syndicates != [] do
    %{io: io, paths: paths, env: env} = Map.merge(@default_deps, deps)

    with {:ok, watch_list_path} <- build_absolute_path(paths[:watch_list], env),
         {:ok, content} <- io.read.(watch_list_path),
         {:ok, watch_list} <- Jason.decode(content),
         current_active_syndicates <- Map.get(watch_list, "active_syndicates", %{}),
         updated_active_syndicates <-
           Enum.reduce(syndicates, current_active_syndicates, fn syndicate_id, acc ->
             Map.delete(acc, Atom.to_string(syndicate_id))
           end),
         {:ok, encoded_content} <-
           watch_list
           |> Map.put("active_syndicates", updated_active_syndicates)
           |> Jason.encode() do
      io.write.(watch_list_path, encoded_content)
    end
  end

  @spec list_active_syndicates(Type.dependencies()) :: Type.list_active_syndicates_response()
  def list_active_syndicates(deps \\ @default_deps) do
    %{io: io, paths: paths, env: env} = Map.merge(@default_deps, deps)

    with {:ok, watch_list_path} <- build_absolute_path(paths[:watch_list], env),
         {:ok, watch_list_data} <- io.read.(watch_list_path),
         {:ok, watch_list} <- Jason.decode(watch_list_data) do
      watch_list
      |> Map.get("active_syndicates")
      |> Maps.to_atom_map(true)
      |> Tuples.to_tagged_tuple()
    end
  end

  ###########
  # Private #
  ###########

  @spec read_product_data(filename(), Type.dependencies()) ::
          {:ok, [Product.t()]} | {:error, :file.posix() | Jason.DecodeError.t()}
  defp read_product_data(filename, %{io: io}) do
    with {:ok, content} <- io.read.(filename),
         {:ok, product_data} <- Jason.decode(content) do
      product_data
      |> Enum.map(&Product.new/1)
      |> Tuples.to_tagged_tuple()
    end
  end

  @spec read_syndicate_data(filename(), Type.dependencies()) ::
          {:ok, [Syndicate.t()]} | {:error, :file.posix() | Jason.DecodeError.t()}
  defp read_syndicate_data(filename, %{io: io}) do
    with {:ok, content} <- io.read.(filename),
         {:ok, syndicate_data} <- Jason.decode(content) do
      syndicate_data
      |> Enum.map(&Syndicate.new/1)
      |> Tuples.to_tagged_tuple()
    end
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
