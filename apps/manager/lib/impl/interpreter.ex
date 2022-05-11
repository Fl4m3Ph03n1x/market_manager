defmodule Manager.Impl.Interpreter do
  @moduledoc """
  Core of the manager, where all the logic and communication with outer
  layers is. Currently, it works more like a bridge between the different ports
  of the application and manages data between them.
  """

  alias Manager.Type
  alias Manager.Impl.PriceAnalyst
  alias Store
  alias Store.Type, as: StoreTypes

  @type order_request :: %{
          (order_type :: String.t()) => String.t(),
          (item_id :: String.t()) => String.t(),
          (platinum :: String.t()) => non_neg_integer,
          (quantity :: String.t()) => non_neg_integer,
          (mod_rank :: String.t()) => non_neg_integer
        }
  @type order_request_without_rank :: %{
          (order_type :: String.t()) => String.t(),
          (item_id :: String.t()) => String.t(),
          (platinum :: String.t()) => non_neg_integer,
          (quantity :: String.t()) => non_neg_integer
        }

  @type dependencies :: keyword(module())

  @mandatory_keys_login_info ["token", "cookie"]
  @actions ["activate", "deactivate", "authenticate"]

  @default_deps [
    store: Store,
    auction_house: AuctionHouse
  ]

  ##########
  # Public #
  ##########

  @spec valid_action?(String.t()) :: boolean
  def valid_action?(action), do: action in @actions

  @spec activate(Type.syndicate(), Type.strategy(), Type.handle(), dependencies) :: :ok
  def activate(syndicate, strategy, handle, deps \\ @default_deps) do
    with {:ok, products} <- list_products(syndicate, deps[:store]),
         total_products <- length(products),
         indexed_products <- Enum.with_index(products) do
      Enum.each(
        indexed_products,
        fn {product, index} ->
          result = place_request(product, syndicate, strategy, deps)
          handle.({:activate, {index + 1, total_products, result}})
        end
      )
    else
      error -> handle.({:activate, error})
    end

    handle.({:activate, :done})
  end

  @spec list_products(Type.syndicate(), store :: module) ::
          StoreTypes.list_products_response()
  defp list_products(syndicate, store), do: store.list_products(syndicate)

  @spec place_request(StoreTypes.product(), Type.syndicate(), Type.strategy(), dependencies) ::
          {:ok, Type.order_id()} | {:error, any}
  defp place_request(
         product,
         syndicate,
         strategy,
         store: store,
         auction_house: auction_house
       ) do
    with updated_product <- update_product_price(product, strategy, auction_house),
         order <- build_order(updated_product),
         {:ok, order_id} <- auction_house.place_order(order),
         {:ok, _order_id} <- store.save_order(order_id, syndicate) do
      {:ok, order_id}
    end
  end

  @spec deactivate(Type.syndicate(), Type.handle(), dependencies()) ::
          Type.deactivate_response()
  def deactivate(syndicate, handle, deps \\ @default_deps) do
    with {:ok, order_ids} <- list_orders(syndicate, deps[:store]),
         total_orders <- length(order_ids),
         indexed_orders <- Enum.with_index(order_ids) do
      Enum.each(
        indexed_orders,
        fn {order, index} ->
          result = delete_order(order, syndicate, deps)
          handle.({:deactivate, {index + 1, total_orders, result}})
        end
      )
    else
      error -> handle.({:deactivate, error})
    end

    handle.({:deactivate, :done})
  end

  @spec list_orders(Type.syndicate(), deps :: module) ::
          StoreTypes.list_orders_response()
  defp list_orders(syndicate, store), do: store.list_orders(syndicate)

  @spec delete_order(Type.order_id(), Type.syndicate(), dependencies()) ::
          {:ok, Type.order_id()} | {:error, atom, Type.order_id()}
  defp delete_order(order_id, syndicate, store: store, auction_house: auction_house) do
    with {:ok, _order_id} <- auction_house.delete_order(order_id),
         {:ok, _order_id} <- store.delete_order(order_id, syndicate) do
      {:ok, order_id}
    else
      {:error, :order_non_existent, order_id} ->
        case store.delete_order(order_id, syndicate) do
          {:error, reason} -> {:error, reason, order_id}
          result -> result
        end

      error ->
        error
    end
  end

  @spec authenticate(Type.credentials(), keyword(module)) :: Type.authenticate_response()
  def authenticate(info, deps \\ @default_deps) do
    with {:ok, login_info} <- validate_login_info(info),
         result <- save_credentials(login_info, deps) do
      handle_authenticate_response(result, info)
    else
      error -> handle_authenticate_response(error, info)
    end
  end

  ###########
  # Private #
  ###########

  @spec update_product_price(StoreTypes.product(), Type.strategy(), deps :: module) ::
          StoreTypes.product()
  defp update_product_price(product, strategy, auction_house_api),
    do:
      product
      |> Map.get("name")
      |> auction_house_api.get_all_orders()
      |> calculate_price(strategy, product)
      |> update_price(product)

  @spec calculate_price(any, Type.strategy(), StoreTypes.product()) :: non_neg_integer
  defp calculate_price({:ok, all_orders}, strategy, product),
    do: PriceAnalyst.calculate_price(product, all_orders, strategy)

  defp calculate_price(_error, _strategy, product), do: Map.get(product, "default_price")

  @spec update_price(non_neg_integer, StoreTypes.product()) :: map
  defp update_price(price, product), do: Map.put(product, "price", price)

  @spec build_order(StoreTypes.product()) :: order_request | order_request_without_rank
  defp build_order(product) do
    case Map.get(product, "rank") do
      "n/a" ->
        %{
          "order_type" => "sell",
          "item_id" => Map.get(product, "id"),
          "platinum" => Map.get(product, "price"),
          "quantity" => Map.get(product, "quantity", 1)
        }

      _ ->
        %{
          "order_type" => "sell",
          "item_id" => Map.get(product, "id"),
          "platinum" => Map.get(product, "price"),
          "quantity" => Map.get(product, "quantity", 1),
          "mod_rank" => Map.get(product, "rank", 0)
        }
    end
  end

  @spec validate_login_info(StoreTypes.login_info()) ::
          {:ok, StoreTypes.login_info()}
          | {:error, {:missing_keys, [String.t()]}}
  defp validate_login_info(info) do
    login_keys =
      info
      |> Map.keys()
      |> MapSet.new()

    obligatory_keys = MapSet.new(@mandatory_keys_login_info)
    missing_keys = MapSet.difference(obligatory_keys, login_keys)

    if Enum.empty?(missing_keys) do
      {:ok, info}
    else
      {:error, {:missing_keys, MapSet.to_list(missing_keys)}}
    end
  end

  @spec save_credentials(Type.credentials(), keyword) :: {:ok, Type.credentials()} | {:error, any}
  defp save_credentials(info, store: store, auction_house: auction_house) do
    with {:ok, res} <- auction_house.update_credentials(info) do
      store.save_credentials(res)
    end
  end

  @spec handle_authenticate_response(
          {:ok, Type.credentials()} | {:error, {:missing_keys, [String.t()]} | :file.posix()},
          Type.credentials()
        ) ::
          {:ok, Type.credentials()}
          | {:error, :unable_to_save_authentication,
             {:missing_mandatory_keys, [String.t()], Type.credentials()}
             | {:file.posix(), Type.credentials()}}
  defp handle_authenticate_response({:error, {:missing_keys, keys}}, login_info),
    do: {:error, :unable_to_save_authentication, {:missing_mandatory_keys, keys, login_info}}

  defp handle_authenticate_response({:error, reason}, login_info),
    do: {:error, :unable_to_save_authentication, {reason, login_info}}

  defp handle_authenticate_response({:ok, _credentials} = ok_response, _login_info),
    do: ok_response
end
