defmodule Store.FileSystem do
  @moduledoc """
  Adapter for the Store port, implements it using the file system.
  """

  require Config
  alias Shared.Data.{Authorization, PlacedOrder, Product, Syndicate, User}
  alias Shared.Utils.Tuples
  alias Store.Type

  @default_deps %{
    io: %{
      read: &File.read/1,
      write: &File.write/2
    },
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
    %{paths: paths, env: env} = deps = Map.merge(@default_deps, deps)

    with {:ok, path} <- build_absolute_path(paths[:products], env),
         {:ok, products} <- read_product_data(path, deps) do
      products
      |> Enum.filter(&Enum.member?(syndicate.catalog, &1.id))
      |> Tuples.to_tagged_tuple()
    end
  end

  @spec list_sell_orders(Type.dependencies()) :: Type.list_sell_orders_response()
  def list_sell_orders(deps \\ @default_deps) do
    %{paths: paths, env: env, io: io} = Map.merge(@default_deps, deps)

    with {:ok, path} <- build_absolute_path(paths[:current_orders], env),
         {:ok, content} <- io.read.(path),
         {:ok, orders_data} <- Jason.decode(content) do
      manual_orders = Map.get(orders_data, "manual") |> Enum.map(&PlacedOrder.new/1)
      automatic_orders = Map.get(orders_data, "automatic") |> Enum.map(&PlacedOrder.new/1)

      Tuples.to_tagged_tuple(%{manual: manual_orders, automatic: automatic_orders})
    end
  end

  @spec save_order(PlacedOrder.t(), Syndicate.id() | nil, Type.dependencies()) ::
          Type.save_order_response()
  def save_order(placed_order, syndicate, deps \\ @default_deps) do
    %{io: io, paths: paths, env: env} = Map.merge(@default_deps, deps)

    with {:ok, path} <- build_absolute_path(paths[:current_orders], env),
         {:ok, content} <- io.read.(path),
         {:ok, orders} <- decode_orders(content),
         updated_orders <- add_order(orders, placed_order, syndicate),
         {:ok, json} <- Jason.encode(updated_orders) do
      io.write.(path, json)
    end
  end

  @spec delete_order(PlacedOrder.t(), Syndicate.id() | nil, Type.dependencies()) ::
          Type.delete_order_response()
  def delete_order(placed_order, syndicate, deps \\ @default_deps) do
    %{io: io, paths: paths, env: env} = Map.merge(@default_deps, deps)

    with {:ok, path} <- build_absolute_path(paths[:current_orders], env),
         {:ok, content} <- io.read.(path),
         {:ok, orders} <- decode_orders(content),
         {:ok, syndicates} <- list_syndicates(),
         updated_orders <- remove_order(orders, placed_order, syndicate, syndicates),
         {:ok, json} <- Jason.encode(updated_orders) do
      io.write.(path, json)
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

  @spec list_active_syndicates(Type.dependencies()) :: Type.list_active_syndicates_response()
  def list_active_syndicates(deps \\ @default_deps) do
    %{io: io, paths: paths, env: env} = Map.merge(@default_deps, deps)

    with {:ok, current_orders_path} <- build_absolute_path(paths[:current_orders], env),
         {:ok, current_orders_data} <- io.read.(current_orders_path),
         {:ok, current_orders} <- Jason.decode(current_orders_data),
         {:ok, syndicates_path} <- build_absolute_path(paths[:syndicates], env),
         {:ok, syndicates_data} <- io.read.(syndicates_path),
         {:ok, syndicates} <- Jason.decode(syndicates_data) do
      current_orders
      |> Map.get("active_syndicates")
      |> Enum.map(fn syndicate_string_id ->
        Enum.find(syndicates, fn %{"id" => id} -> id == syndicate_string_id end)
      end)
      |> Enum.map(&Syndicate.new/1)
      |> Tuples.to_tagged_tuple()
    end
  end

  ###########
  # Private #
  ###########

  @spec read_product_data(
          filename :: String.t(),
          Type.dependencies()
        ) ::
          {:ok, [Product.t()]} | {:error, :file.posix() | Jason.DecodeError.t()}
  defp read_product_data(filename, %{io: io}) do
    with {:ok, content} <- io.read.(filename),
         {:ok, product_data} <- Jason.decode(content) do
      product_data
      |> Enum.map(&Product.new/1)
      |> Tuples.to_tagged_tuple()
    end
  end

  @spec decode_orders(content :: String.t()) ::
          {:ok, Type.all_orders_store()} | {:error, Jason.DecodeError.t()}
  defp decode_orders(""),
    do: {:ok, %{automatic: [], manual: [], active_syndicates: []}}

  defp decode_orders(content) do
    case Jason.decode(content) do
      {:ok, decoded_content} ->
        decoded_content
        |> Enum.map(fn
          {"active_syndicates", ids} ->
            {:active_syndicates, Enum.map(ids, &String.to_atom/1)}

          {order_type, orders} ->
            {String.to_atom(order_type), Enum.map(orders, &PlacedOrder.new/1)}
        end)
        |> Map.new()
        |> Tuples.to_tagged_tuple()

      err ->
        err
    end
  end

  @spec add_order(Type.sell_orders_store(), PlacedOrder.t(), Syndicate.id() | nil) ::
          Type.sell_orders_store()
  defp add_order(sell_orders, placed_order, nil) do
    updated_manual_orders = Enum.uniq([placed_order | Map.get(sell_orders, :manual)])

    Map.put(sell_orders, :manual, updated_manual_orders)
  end

  defp add_order(sell_orders, placed_order, syndicate) do
    updated_automatic_orders = Enum.uniq([placed_order | Map.get(sell_orders, :automatic)])
    updated_active_syndicates = Enum.uniq([syndicate | Map.get(sell_orders, :active_syndicates)])

    sell_orders
    |> Map.put(:automatic, updated_automatic_orders)
    |> Map.put(:active_syndicates, updated_active_syndicates)
  end

  @spec remove_order(Type.sell_orders_store(), PlacedOrder.t(), Syndicate.id() | nil, [
          Syndicate.t()
        ]) ::
          Type.sell_orders_store()
  defp remove_order(sell_orders, placed_order, nil, _syndicates) do
    updated_manual_orders = Map.get(sell_orders, :manual) -- [placed_order]

    Map.put(sell_orders, :manual, updated_manual_orders)
  end

  defp remove_order(sell_orders, placed_order, syndicate_id, syndicates) do
    updated_automatic_orders = Map.get(sell_orders, :automatic) -- [placed_order]

    item_ids_on_sale = Enum.map(updated_automatic_orders, fn %{item_id: id} -> id end)

    syndicate_item_ids =
      syndicates
      |> Enum.find(fn syn -> syn.id == syndicate_id end)
      |> Map.get(:catalog)

    remove_syndicate? = item_ids_on_sale -- syndicate_item_ids == item_ids_on_sale

    updated_active_syndicates =
      if remove_syndicate? do
        Map.get(sell_orders, :active_syndicates) -- [syndicate_id]
      else
        Map.get(sell_orders, :active_syndicates)
      end

    sell_orders
    |> Map.put(:automatic, updated_automatic_orders)
    |> Map.put(:active_syndicates, updated_active_syndicates)
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
