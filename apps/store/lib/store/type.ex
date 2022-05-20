defmodule Store.Type do
  @moduledoc """
  Contains the types for the Store library.
  Because we separate this file from the API and implementation, we also avoid
  a cyclical dependency between them.
  """

  ##########
  # Types  #
  ##########

  @type login_info :: %{
          (token :: String.t()) => String.t(),
          (cookie :: String.t()) => String.t()
        }
  @type order_id :: String.t()
  @type syndicate :: String.t()
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
          (cephalon_simaris :: String.t()) => [order_id]
        }
  @type error :: {:error, any}

  #############
  # Responses #
  #############

  @type get_credentials_response :: {:ok, login_info} | error
  @type save_credentials_response :: {:ok, login_info} | error
  @type list_products_response :: {:ok, [product]} | error
  @type list_orders_response :: {:ok, [order_id]} | error
  @type save_order_response :: {:ok, order_id} | error
  @type delete_order_response :: {:ok, order_id} | error
  @type syndicate_exists_response :: {:ok, boolean} | error
end
