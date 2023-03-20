defmodule Store.Type do
  @moduledoc """
  Contains the types for the Store library.
  Because we separate this file from the API and implementation, we also avoid
  a cyclical dependency between them.
  """

  alias Shared.Data.{Authorization, Product, User}

  ##########
  # Types  #
  ##########

  @type order_id :: String.t()
  @type syndicate :: String.t()
  @type dependencies :: keyword(module)
  @type all_orders_store :: %{
          (new_loka :: String.t()) => [order_id],
          (perrin_sequence :: String.t()) => [order_id],
          (red_veil :: String.t()) => [order_id],
          (cephalon_simaris :: String.t()) => [order_id]
        }
  @type error :: {:error, any}

  #############
  # Responses #
  #############

  @type get_login_data :: {:ok, {Authorization.t(), User.t()} | nil} | error
  @type save_login_data_response :: :ok | error
  @type delete_login_data_response :: :ok | error
  @type list_products_response :: {:ok, [Product.t()]} | error
  @type list_orders_response :: {:ok, [order_id]} | error
  @type save_order_response :: :ok | error
  @type delete_order_response :: :ok | error
  @type syndicate_exists_response :: {:ok, boolean} | error
end
