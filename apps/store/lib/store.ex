defmodule Store do
  @moduledoc """
  Port for the persistency layer.
  This module contains the Public API for the storage app.
  """

  alias Shared.Data.{Authorization, Product, Strategy, Syndicate, User}
  alias Store.FileSystem
  alias Store.Type

  @doc """
  Lists the products for the syndicates with the given ids.

  Example:
  ```
  > alias Shared.Data.Product

  > Store.list_products([:red_veil])
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

  > Store.list_products([:invalid_syndicate_id])
  {:error, {:syndicate_not_found, [:invalid_syndicate_id]}}
  ```
  """
  @spec list_products([Syndicate.id()]) :: Type.list_products_response()
  defdelegate list_products(syndicates), to: FileSystem

  @doc """
  Returns the product with the given id.

  Example:
  ```
  > alias Shared.Data.{Product}

  > Store.get_product_by_id("8ee5b3b0-fa43-4dbc-9363-a52930dc742e")
  {:ok,
    %Product{
      name: "Eternal War",
      id: "8ee5b3b0-fa43-4dbc-9363-a52930dc742e",
      min_price: 14,
      default_price: 15,
      quantity: 1,
      rank: 0
    }
  }

  > Store.get_product_by_id("non-existent-id")
  {:error, :product_not_found}

  > Store.get_product_by_id("8ee5b3b0-fa43-4dbc-9363-a52930dc742e")
  {:error, :enoent}
  ```
  """
  @spec get_product_by_id(Product.id()) :: Type.get_product_by_id_response()
  defdelegate get_product_by_id(id), to: FileSystem

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
  Marks the given syndicates as activated with the given strategy.

  Example:
  ```
  > alias Shared.Data.Syndicate

  > Store.activate_syndicates(%{red_veil: :top_five_average, new_loka: :top_five_average})
  :ok

  > Store.activate_syndicates(%{red_veil: :top_five_average, new_loka: :top_five_average})
  {:error, :enoent}
  """
  @spec activate_syndicates(%{Syndicate.id() => Strategy.id()}) ::
          Type.activate_syndicates_response()
  defdelegate activate_syndicates(syndicates_with_strategy), to: FileSystem

  @doc """
  Removes the syndicates with the given ids from the set of active syndicates.

  Example:
  ```
  > alias Shared.Data.Syndicate

  > Store.deactivate_syndicates([:red_veil, :new_loka])
  :ok

  > Store.deactivate_syndicates([:red_veil, :new_loka])
  {:error, :enoent}
  """
  @spec deactivate_syndicates([Syndicate.id()]) :: Type.deactivate_syndicates_response()
  defdelegate deactivate_syndicates(syndicates), to: FileSystem

  @doc """
  Returns the syndicates currently active. An active syndicate is a syndicate with orders in `current_orders`.

  Example:
  ```
  > alias Shared.Data.Syndicate

  > Store.list_active_syndicates()
  {:ok, %{red_veil: :top_five_average, new_loka: :top_five_average}}

  > Store.list_active_syndicates()
  {:error, :enoent}
  ```
  """
  @spec list_active_syndicates :: Type.list_active_syndicates_response()
  defdelegate list_active_syndicates, to: FileSystem
end
