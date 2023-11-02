defmodule Store.FileSystem do
  @moduledoc """
  Adapter for the Store port, implements it using the file system.
  """

  alias Shared.Data.{Authorization, PlacedOrder, Product, Syndicate, User}
  alias Shared.Utils.Tuples
  alias Store.Type

  @current_orders_filename Application.compile_env!(:store, :current_orders)
  @products_filename Application.compile_env!(:store, :products)
  @syndicates_filename Application.compile_env!(:store, :syndicates)
  @setup_filename Application.compile_env!(:store, :setup)

  @default_deps [
    file: File,
    paths: [
      current_orders: @current_orders_filename,
      products: @products_filename,
      syndicates: @syndicates_filename,
      setup: @setup_filename
    ]
  ]

  ##########
  # Public #
  ##########

  @spec list_products(Syndicate.t(), Type.dependencies()) :: Type.list_products_response()
  def list_products(syndicate, deps \\ @default_deps) do
    deps = Keyword.merge(@default_deps, deps)
    products_filename = deps[:paths][:products]

    with {:ok, products} <- read_syndicate_data(products_filename, syndicate, deps) do
      {:ok, Enum.map(products, &Product.new/1)}
    end
  end

  @spec list_orders(Syndicate.t(), Type.dependencies()) :: Type.list_orders_response()
  def list_orders(syndicate, deps \\ @default_deps) do
    [file: _file, paths: paths] = Keyword.merge(@default_deps, deps)
    current_orders_filename = paths[:current_orders]

    with {:ok, data} <- read_syndicate_data(current_orders_filename, syndicate, deps) do
      {:ok, Enum.map(data, &PlacedOrder.new/1)}
    end
  end

  @spec save_order(PlacedOrder.t(), Syndicate.t(), Type.dependencies()) ::
          Type.save_order_response()
  def save_order(placed_order, syndicate, deps \\ @default_deps) do
    [file: file, paths: paths] = Keyword.merge(@default_deps, deps)
    current_orders_filename = paths[:current_orders]

    with {:ok, content} <- file.read(current_orders_filename),
         {:ok, orders} <- decode_orders(content),
         {:ok, updated_orders} <- add_order(orders, placed_order, syndicate),
         {:ok, json} <- Jason.encode(updated_orders) do
      file.write(current_orders_filename, json)
    end
  end

  @spec delete_order(PlacedOrder.t(), Syndicate.t(), Type.dependencies()) ::
          Type.delete_order_response()
  def delete_order(placed_order, syndicate, deps \\ @default_deps) do
    [file: file, paths: paths] = Keyword.merge(@default_deps, deps)
    current_orders_filename = paths[:current_orders]

    with {:ok, content} <- file.read(current_orders_filename),
         {:ok, orders} <- decode_orders(content),
         {:ok, updated_orders} <- remove_order(orders, placed_order, syndicate),
         {:ok, json} <- Jason.encode(updated_orders) do
      file.write(current_orders_filename, json)
    end
  end

  @spec save_login_data(Authorization.t(), User.t(), Type.dependencies()) ::
          Type.save_login_data_response()
  def save_login_data(auth, user, deps \\ @default_deps) do
    [file: file, paths: paths] = Keyword.merge(@default_deps, deps)
    setup_filename = paths[:setup]

    with {:ok, data} <- Jason.encode(%{authorization: auth, user: user}) do
      file.write(setup_filename, data)
    end
  end

  @spec get_login_data(Type.dependencies()) :: Type.get_login_data_response()
  def get_login_data(deps \\ @default_deps) do
    [file: file, paths: paths] = Keyword.merge(@default_deps, deps)
    setup_filename = paths[:setup]

    with {:ok, encoded_data} <- file.read(setup_filename),
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
    [file: file, paths: paths] = Keyword.merge(@default_deps, deps)
    setup_filename = paths[:setup]

    with {:ok, data} <- Jason.encode(%{}) do
      file.write(setup_filename, data)
    end
  end

  @spec list_syndicates(Type.dependencies()) :: Type.list_syndicates_response()
  def list_syndicates(deps \\ @default_deps) do
    [file: file, paths: paths] = Keyword.merge(@default_deps, deps)
    syndicates_filename = paths[:syndicates]

    with {:ok, content} <- file.read(syndicates_filename),
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
  defp read_syndicate_data(filename, syndicate, file: file, paths: _path) do
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
end
