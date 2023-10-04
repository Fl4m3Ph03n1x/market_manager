defmodule Store.Type do
  @moduledoc """
  Contains the types for the Store library.
  Because we separate this file from the API and implementation, we also avoid
  a cyclical dependency between them.
  """

  alias Jason
  alias Shared.Data.{Authorization, PlacedOrder, Product, Syndicate, User}

  ##########
  # Types  #
  ##########

  @type dependencies :: keyword(module)
  @type all_orders_store :: %{String.t() => [PlacedOrder.t()]}

  #############
  # Responses #
  #############

  @type get_login_data_response ::
          {:ok, {Authorization.t(), User.t()} | nil}
          | {:error, :file.posix() | Jason.DecodeError.t()}
  @type save_login_data_response :: :ok | {:error, :file.posix() | Jason.EncodeError.t()}
  @type delete_login_data_response :: :ok | {:error, :file.posix() | Jason.EncodeError.t()}
  @type list_products_response ::
          {:ok, [Product.t()]}
          | {:error, :file.posix() | Jason.DecodeError.t() | :syndicate_not_found}
  @type list_orders_response ::
          {:ok, [PlacedOrder.t()]}
          | {:error, :file.posix() | Jason.DecodeError.t() | :syndicate_not_found}
  @type save_order_response :: :ok | {:error, :file.posix() | Jason.DecodeError.t() | Jason.EncodeError.t()}
  @type delete_order_response :: :ok | {:error, :file.posix() | Jason.DecodeError.t() | Jason.EncodeError.t()}
  @type list_syndicates_response :: {:ok, [Syndicate.t()]} | {:error, :file.posix() | Jason.DecodeError.t()}
end
