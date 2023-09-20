defmodule Store do
  @moduledoc """
  Port for the persistency layer.
  This module contains the Public API for the storage app.
  """

  alias Shared.Data.{Authorization, PlacedOrder, Syndicate, User}
  alias Store.FileSystem
  alias Store.Type

  @doc """
  Lists the products from the given syndicate.

  Example:
  ```
  > alias Shared.Data.{Product, Syndicate}

  > syndicate = Syndicate.new(name: "Red Veil", id: :red_veil)
  > Store.list_products(syndicate)
  {:ok, [
    %Product{
      name: "Eternal War",
      id: "8ee5b3b0-fa43-4dbc-9363-a52930dc742e",
      min_price: 14,
      default_price: 15,
      quantity: 1,
      rank: 0
    },
    ...
  ]}

  > invalid_syndicate = Syndicate.new(name: "Bad Synd", id: :bad_syndicate)
  > Store.list_products(invalid_syndicate)
  {:error, :syndicate_not_found}
  ```
  """
  @spec list_products(Syndicate.t()) :: Type.list_products_response()
  defdelegate list_products(syndicate), to: FileSystem

  @doc """
  Lists all placed orders from the given syndicate.

  Example:
  ```
  > alias Shared.Data.{PlacedOrder, Syndicate}

  > syndicate = Syndicate.new(name: "Red Veil", id: :red_veil)
  > Store.list_orders(syndicate)
  {:ok, [
    %PlacedOrder{item_name: "Exothermic", order_id: "5526aec1e779896af9418266"},
    %PlacedOrder{item_name: "Tribunal", order_id: "5ea087d1c160d001303f9ed7"},
    ...
  ]}

  > invalid_syndicate = Syndicate.new(name: "Bad Synd", id: :bad_syndicate)
  > Store.list_orders(invalid_syndicate)
  {:error, :syndicate_not_found}
  ```
  """
  @spec list_orders(Syndicate.t()) :: Type.list_orders_response()
  defdelegate list_orders(syndicate), to: FileSystem

  @doc """
  Saves the given placed_order for the given syndicate in the storage system.

  Example:
  ```
  > alias Shared.Data.{PlacedOrder, Syndicate}

  > Store.save_order(
    %PlacedOrder{item_name: "Exothermic", order_id: "5526aec1e779896af9418266"},
    Syndicate.new(name: "Red Veil", id: :red_veil)
  )
  :ok

  > invalid_syndicate = Syndicate.new(name: "Bad Synd", id: :bad_syndicate)
  > Store.save_order(invalid_syndicate)
  {:error, :enoent}
  ```
  """
  @spec save_order(PlacedOrder.t(), Syndicate.t()) :: Type.save_order_response()
  defdelegate save_order(placed_order, syndicate), to: FileSystem

  @doc """
  Deletes the given placed_order from the given syndicate from the storage system.

  Example:
  ```
  > alias Shared.Data.{PlacedOrder, Syndicate}

  > Store.delete_order(
    %PlacedOrder{item_name: "Exothermic", order_id: "5526aec1e779896af9418266"},
    Syndicate.new(name: "Red Veil", id: :red_veil)
  )
  :ok

  > invalid_syndicate = Syndicate.new(name: "Bad Synd", id: :bad_syndicate)
  > Store.delete_order(invalid_syndicate)
  {:error, :enoent}
  ```
  """
  @spec delete_order(PlacedOrder.t(), Syndicate.t()) :: Type.delete_order_response()
  defdelegate delete_order(placed_order, syndicate), to: FileSystem

  @doc """
  Saves the login information from the user into the storage system.
  Does not perform validation.

  Example:
  ```
  > alias Shared.Data.{Authorization, User}

  > Store.save_login_data(
    %Authorization{token: "a_token", cookie: "a_cookie"},
    %User{ingame_name: "username", patreon?: false}
  )
  :ok

  > Store.save_login_data(
    %Authorization{token: "a_token", cookie: "a_cookie"},
    %User{ingame_name: "username", patreon?: false}
  )
  {:error, :enoent}
  ```
  """
  @spec save_login_data(Authorization.t(), User.t()) :: Type.save_login_data_response()
  defdelegate save_login_data(auth, user), to: FileSystem

  @doc """
  Deletes any login information from the storage system.

  Example:
  ```
  > Store.delete_login_data()
  :ok

  > Store.delete_login_data()
  {:error, :enoent}
  ```
  """
  @spec delete_login_data :: Type.delete_login_data_response()
  defdelegate delete_login_data, to: FileSystem

  @doc """
  Retrieves the user's login data from Storage.

  Example:
  ```
  > Store.get_login_data()
  {:ok, {
    %Authorization{token: "a_token", cookie: "a_cookie"},
    %User{ingame_name: "username", patreon?: false}
  }}

  > Store.get_login_data()
  {:error, :enoent}
  ```
  """
  @spec get_login_data :: Type.get_login_data_response()
  defdelegate get_login_data, to: FileSystem

  @doc """
  Returns all the syndicates currently stored. The fact a syndicate is stored does not mean it has products, nor orders.

  Example:
  ```
  > alias Shared.Data.Syndicate

  > Store.list_syndicates()
  {:ok, [%Syndicate{name: "Red Veil", id: :red_veil}, %Syndicate{name: "New Loka", id: :new_loka}]}

  > Store.list_syndicates()
  {:error, :enoent}
  ```
  """
  @spec list_syndicates :: Type.list_syndicates_response()
  defdelegate list_syndicates, to: FileSystem
end
