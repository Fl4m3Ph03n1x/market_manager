defmodule Store do
  @moduledoc """
  Port for the persistency layer.
  This module contains the Public API for the storage app.
  """

  alias Store.FileSystem
  alias Store.Type

  @doc """
  Lists the products from the given syndicate.

  Example:
  ```
  > Store.list_products("red_veil")
  {:ok, [
    %{
      "name" => "Eternal War",
      "id" => "8ee5b3b0-fa43-4dbc-9363-a52930dc742e",
      "min_price" => 14,
      "default_price" => 15,
      "quantity" => 1,
      "rank" => 0
    },
    ...
  ]}

  > Store.list_products("invalid_syndicate")
  {:error, :syndicate_not_found}
  ```
  """
  @spec list_products(Type.syndicate) :: Type.list_products_response
  defdelegate list_products(syndicate), to: FileSystem

  @doc """
  Lists the ids of currently active orders from the given syndicate.

  Example:
  ```
  > Store.list_orders("red_veil")
  {:ok, ["5a750686-956f-42a6-8194-11925ec9281e", "58f0b7e7-0ded-4932-8ccd-380cc5634c82", ...]}

  > Store.list_orders("invalid_syndicate")
  {:error, :syndicate_not_found}
  ```
  """
  @spec list_orders(Type.syndicate) :: Type.list_orders_response
  defdelegate list_orders(syndicate), to: FileSystem

  @doc """
  Saves the given orderId for the given syndicate in the storage system.

  Example:
  ```
  > Store.save_order("00f83ca2-67d9-4019-9fea-587b9fc4037c", "red_veil")
  {:ok, "00f83ca2-67d9-4019-9fea-587b9fc4037c"}

  > Store.save_order("invalid_syndicate")
  {:error, :enoent}
  ```
  """
  @spec save_order(Type.order_id, Type.syndicate) :: Type.save_order_response
  defdelegate save_order(order_id, syndicate), to: FileSystem

  @doc """
  Deletes the given orderId from the given syndicate from the storage system.

  Example:
  ```
  > Store.delete_order("00f83ca2-67d9-4019-9fea-587b9fc4037c", "red_veil")
  {:ok, "00f83ca2-67d9-4019-9fea-587b9fc4037c"}

  > Store.delete_order("invalid_syndicate")
  {:error, :enoent}
  ```
  """
  @spec delete_order(Type.order_id, Type.syndicate) :: Type.delete_order_response
  defdelegate delete_order(order_id, syndicate), to: FileSystem

  @doc """
  Returns true if the given syndicate exists, false otherwise. Returns an
  error if an error occurs.

  Example:
  ```
  > Store.syndicate_exists?(red_veil")
  {:ok, true}

  > Store.syndicate_exists?("nonexistent_syndicate")
  {:ok, false}

  > Store.syndicate_exists?("syndicate") # world explodes meanwhile
  {:error, :enoent}
  ```
  """
  @spec syndicate_exists?(Type.syndicate) :: {:ok, boolean} | Type.error
  defdelegate syndicate_exists?(syndicate), to: FileSystem

  @doc """
  Saves the authentication information from the user into the storage system.
  Does not perform validation.

  Example:
  ```
  > Store.save_credentials(%{"token" => "a_token", "cookie" => "a_cookie"})
  {:ok, %{"token" => "a_token", "cookie" => "a_cookie"}}

  > Store.save_credentials(%{"token" => "a_token", "cookie" => "a_cookie"})
  {:error, :no_permissions}
  ```
  """
  @spec save_credentials(Type.login_info) :: Type.save_credentials_response
  defdelegate save_credentials(login_info), to: FileSystem

  @doc """
  Retrieves the user's authentication from Storage.

  Example:
  ```
  > Store.get_credentials()
  {:ok, %{"token" => "a_token", "cookie" => "a_cookie"}}

  > Store.get_credentials()
  {:error, :enonent}
  ```
  """
  @spec get_credentials :: Type.get_cedentials_response
  defdelegate get_credentials, to: FileSystem
end
