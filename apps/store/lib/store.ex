defmodule Store do
  @moduledoc """
  Port for the persistency layer.
  This module contains the Public API for the storage app.
  """

  alias Store.FileSystem

  ##########
  # Types  #
  ##########

  @type login_info :: %{
    (token :: String.t()) => String.t(),
    (cookie :: String.t()) => String.t()
  }
  @type order_id :: String.t
  @type syndicate :: String.t
  @type deps :: keyword
  @type product :: %{
    (name :: String.t()) => String.t(),
    (id :: String.t()) => String.t(),
    (min_price :: String.t()) => non_neg_integer,
    (default_price :: String.t()) => non_neg_integer,
    (quantity :: String.t()) => non_neg_integer,
    (rank :: String.t()) => non_neg_integer | String.t()
  }
  @type all_orders_store :: %{
    (new_loka :: String.t()) => [order_id],
    (perrin_sequence :: String.t()) => [order_id],
    (red_veil :: String.t()) => [order_id],
    (simaris :: String.t()) => [order_id]
  }
  @type error :: {:error, any}

  #############
  # Responses #
  #############

  @type setup_response :: {:ok, login_info} | {:error, :file.posix}
  @type list_products_response :: {:ok, [product]} | error
  @type list_orders_response :: {:ok, [order_id]} | error
  @type save_order_response :: {:ok, order_id} | error
  @type delete_order_response :: {:ok, order_id} | error
  @type syndicate_exists_response :: {:ok, boolean} | error

  ##########
  # Public #
  ##########

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
  @spec list_products(syndicate) :: list_products_response
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
  @spec list_orders(syndicate) :: list_orders_response
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
  @spec save_order(order_id, syndicate) :: save_order_response
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
  @spec delete_order(order_id, syndicate) :: delete_order_response
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
  @spec syndicate_exists?(syndicate) :: {:ok, boolean} | error
  defdelegate syndicate_exists?(syndicate), to: FileSystem

  @doc """
  Saves the setup information from the user into the storage system.
  Does not perform validation.

  Example:
  ```
  > Store.setup(%{"token" => "a_token", "cookie" => "a_cookie"})
  {:ok, %{"token" => "a_token", "cookie" => "a_cookie"}}

  > Store.setup(%{"token" => "a_token", "cookie" => "a_cookie"})
  {:error, :no_permissions}
  ```
  """
  @spec setup(login_info) :: setup_response
  defdelegate setup(login_info), to: FileSystem
end
