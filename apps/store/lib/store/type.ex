defmodule Store.Type do
  @moduledoc """
  Contains the types for the Store library.
  Because we separate this file from the API and implementation, we also avoid
  a cyclical dependency between them.
  """

  alias Jason
  alias Shared.Data.{Authorization, PlacedOrder, Product, User}

  ##########
  # Types  #
  ##########

  @type syndicate :: String.t()
  @type dependencies :: keyword(module)
  @type all_orders_store :: %{
          required(arbiters_of_hexis :: String.t()) => [PlacedOrder.t()],
          required(cephalon_simaris :: String.t()) => [PlacedOrder.t()],
          required(cephalon_suda :: String.t()) => [PlacedOrder.t()],
          required(new_loka :: String.t()) => [PlacedOrder.t()],
          required(perrin_sequence :: String.t()) => [PlacedOrder.t()],
          required(red_veil :: String.t()) => [PlacedOrder.t()],
          required(steel_meridian :: String.t()) => [PlacedOrder.t()]
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
          {:ok, [PlacedOrder.t()]}
          | {:error, :file.posix() | Jason.DecodeError.t() | :syndicate_not_found}
  @type save_order_response ::
          :ok | {:error, :file.posix() | Jason.DecodeError.t() | Jason.EncodeError.t()}
  @type delete_order_response ::
          :ok | {:error, :file.posix() | Jason.DecodeError.t() | Jason.EncodeError.t()}
end
