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

  > syndicate = Syndicate.new(name: "Red Veil", id: :red_veil, catalog: ["8ee5b3b0-fa43-4dbc-9363-a52930dc742e"])
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

  > invalid_syndicate = Syndicate.new(name: "Bad Synd", id: :bad_syndicate, catalog: [])
  > Store.list_products(invalid_syndicate)
  {:error, :syndicate_not_found}
  ```
  """
  @spec list_products(Syndicate.t()) :: Type.list_products_response()
  defdelegate list_products(syndicate), to: FileSystem

  @doc """
  Lists all placed sell orders.

  Example:
  ```
  > alias Shared.Data.PlacedOrder

  > Store.list_sell_orders()
  {:ok, %{
    manual: [
      %PlacedOrder{item_id: "5740c1879d238d4a03d28518", order_id: "5ee71a2604d55c0a5cbdc3c2"}
    ],
    automatic: [
      %PlacedOrder{item_id: "5b00231bac0f7e006fd6f7b4", order_id: "5ee71a2604d55c0a5cbdc3e3"},
      %PlacedOrder{item_id: "54a74454e779892d5e5155d5", order_id: "5ee71a2604d55c0a5cbdc3d4"}
    ]
  }}

  > Store.list_sell_orders()
  {:error, :enoent}
  ```
  """
  @spec list_sell_orders :: Type.list_sell_orders_response()
  defdelegate list_sell_orders, to: FileSystem

  @doc """
  Resets all the manual and automatic orders by deleting everything.

  Example: 

  > Store.reset_orders()
  :ok


  > Store.reset_orders()
  {:error, :enoent}

  """
  @spec reset_orders :: Type.reset_orders_response()
  defdelegate reset_orders, to: FileSystem

  @doc """
  Saves the given placed_order in the storage system.
  If a syndicate is given, the order is considered automatic and the syndicate will be added to the list of active
  syndicates.
  If no syndicate is given, the order will be considered a manual one, and no syndicate manipulation occurs.

  Example:
  ```
  > alias Shared.Data.PlacedOrder 

  > Store.save_order(%PlacedOrder{item_name: "Exothermic", order_id: "5526aec1e779896af9418266"}, :red_veil)
  :ok

  > Store.save_order(:some_syndicate)
  {:error, :enoent}
  ```
  """
  @spec save_order(PlacedOrder.t(), Syndicate.id() | nil) :: Type.save_order_response()
  defdelegate save_order(placed_order, syndicate), to: FileSystem

  @doc """
  Deletes the given placed_order from the given syndicate from the storage system.
  If a syndicate is given, the order is considered automatic and the syndicate will be manipulated accordingly.
  If no syndicate is given, the order will be considered a manual one, ano no syndicate manipulation occurs.

  Example:
  ```
  > alias Shared.Data.PlacedOrder

  > Store.delete_order(%PlacedOrder{item_name: "Exothermic", order_id: "5526aec1e779896af9418266"}, :red_veil)
  :ok

  > Store.delete_order(:some_syndicate)
  {:error, :enoent}
  ```
  """
  @spec delete_order(PlacedOrder.t(), Syndicate.id() | nil) :: Type.delete_order_response()
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
  > alias Shared.Data.{Authorization, User}

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
  {:ok, [%Syndicate{name: "Red Veil", id: :red_veil, catalog: []}, %Syndicate{name: "New Loka", id: :new_loka, catalog: []}]}

  > Store.list_syndicates()
  {:error, :enoent}
  ```
  """
  @spec list_syndicates :: Type.list_syndicates_response()
  defdelegate list_syndicates, to: FileSystem

  @doc """
  Returns the syndicates currently active. An active syndicate is a syndicate with orders in `current_orders`.

  Example:
  ```
  > alias Shared.Data.Syndicate

  > Store.list_active_syndicates()
  {:ok, [%Syndicate{name: "Red Veil", id: :red_veil, catalog: []}, %Syndicate{name: "New Loka", id: :new_loka, catalog: []}]}

  > Store.list_active_syndicates()
  {:error, :enoent}
  ```
  """
  @spec list_active_syndicates :: Type.list_active_syndicates_response()
  defdelegate list_active_syndicates, to: FileSystem
end
