defmodule Store.Type do
  @moduledoc """
  Contains the types for the Store library.
  Because we separate this file from the API and implementation, we also avoid
  a cyclical dependency between them.
  """

  alias Jason
  alias Shared.Data.{Authorization, Product, User}

  ##########
  # Types  #
  ##########

  @type order_id :: String.t()
  @type syndicate :: String.t()
  @type dependencies :: keyword(module)
  @type all_orders_store :: %{
          (arbiters_of_hexis :: String.t()) => [order_id],
          (cephalon_simaris :: String.t()) => [order_id],
          (cephalon_suda :: String.t()) => [order_id],
          (new_loka :: String.t()) => [order_id],
          (perrin_sequence :: String.t()) => [order_id],
          (red_veil :: String.t()) => [order_id],
          (steel_meridian :: String.t()) => [order_id]
        }

  #############
  # Responses #
  #############

  @type get_login_data ::
          {:ok, {Authorization.t(), User.t()} | nil}
          | {:error, :file.posix() | Jason.DecodeError.t() | :syndicate_not_found}
  @type save_login_data_response ::
          :ok | {:error, :file.posix() | Jason.EncodeError.t() | :syndicate_not_found}
  @type delete_login_data_response ::
          :ok | {:error, :file.posix() | Jason.EncodeError.t() | :syndicate_not_found}
  @type list_products_response ::
          {:ok, [Product.t()]}
          | {:error, :file.posix() | Jason.DecodeError.t() | :syndicate_not_found}
  @type list_orders_response ::
          {:ok, [order_id]}
          | {:error, :file.posix() | Jason.DecodeError.t() | :syndicate_not_found}
  @type save_order_response ::
          :ok | {:error, :file.posix() | Jason.DecodeError.t() | Jason.EncodeError.t()}
  @type delete_order_response ::
          :ok | {:error, :file.posix() | Jason.DecodeError.t() | Jason.EncodeError.t()}
end
