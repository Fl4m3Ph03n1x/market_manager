defmodule Store do
  @moduledoc """
  Port for the persistency layer.
  This module contains the Public API for the storage app.
  """

  alias Shared.Data.{Authorization, PlacedOrder, User}
  alias Store.FileSystem
  alias Store.Type

  @doc """
  Lists the products from the given syndicate.

  Example:
  ```
  alias Shared.Data.Product

  > Store.list_products("red_veil")
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

  > Store.list_products("invalid_syndicate")
  {:error, :syndicate_not_found}
  ```
  """
  @spec list_products(Type.syndicate()) :: Type.list_products_response()
  defdelegate list_products(syndicate), to: FileSystem

  @doc """
  Lists all placed orders from the given syndicate.

  Example:
  ```
  alias Shared.Data.PlacedOrder

  > Store.list_orders("red_veil")
  {:ok, [
    %PlacedOrder{item_name: "Exothermic", order_id: "5526aec1e779896af9418266"},
    %PlacedOrder{item_name: "Tribunal", order_id: "5ea087d1c160d001303f9ed7"},
    ...
  ]}

  > Store.list_orders("invalid_syndicate")
  {:error, :syndicate_not_found}
  ```
  """
  @spec list_orders(Type.syndicate()) :: Type.list_orders_response()
  defdelegate list_orders(syndicate), to: FileSystem

  @doc """
  Saves the given placed_order for the given syndicate in the storage system.

  Example:
  ```
  alias Shared.Data.PlacedOrder

  > Store.save_order(
    %PlacedOrder{item_name: "Exothermic", order_id: "5526aec1e779896af9418266"},
    "red_veil"
  )
  :ok

  > Store.save_order("invalid_syndicate")
  {:error, :enoent}
  ```
  """
  @spec save_order(PlacedOrder.t(), Type.syndicate()) :: Type.save_order_response()
  defdelegate save_order(placed_order, syndicate), to: FileSystem

  @doc """
  Deletes the given placed_order from the given syndicate from the storage system.

  Example:
  ```
  > Store.delete_order(
    %PlacedOrder{item_name: "Exothermic", order_id: "5526aec1e779896af9418266"},
    "red_veil"
  )
  :ok

  > Store.delete_order("invalid_syndicate")
  {:error, :enoent}
  ```
  """
  @spec delete_order(PlacedOrder.t(), Type.syndicate()) :: Type.delete_order_response()
  defdelegate delete_order(placed_order, syndicate), to: FileSystem

  @doc """
  Saves the login information from the user into the storage system.
  Does not perform validation.

  Example:
  ```
  alias Shared.Data.{Authorization, User}

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
end
