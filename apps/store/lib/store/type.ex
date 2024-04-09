defmodule Store.Type do
  @moduledoc """
  Contains the types for the Store library.
  Because we separate this file from the API and implementation, we also avoid
  a cyclical dependency between them.
  """

  alias WebInterface.Persistence.Syndicate
  alias Jason
  alias Shared.Data.{Authorization, PlacedOrder, Product, Syndicate, User}

  ##########
  # Types  #
  ##########

  @type dependencies :: map()
  @type sell_orders_store :: %{
          manual: [PlacedOrder.t()],
          automatic: [PlacedOrder.t()],
          active_syndicates: [Syndicate.id()]
        }

  #############
  # Responses #
  #############

  @type get_login_data_response ::
          {:ok, {Authorization.t(), User.t()} | nil}
          | {:error, :file.posix() | Jason.DecodeError.t()}
  @type save_login_data_response :: :ok | {:error, :file.posix() | Jason.EncodeError.t()}
  @type delete_login_data_response :: :ok | {:error, :file.posix() | Jason.EncodeError.t()}
  @type list_products_response ::
          {:ok, [Product.t()]} | {:error, :file.posix() | Jason.DecodeError.t()}
  @type list_sell_orders_response ::
          {:ok, %{manual: [PlacedOrder.t()], automatic: [PlacedOrder.t()]}}
          | {:error, :file.posix() | Jason.DecodeError.t()}
  @type save_order_response ::
          :ok | {:error, :file.posix() | Jason.DecodeError.t() | Jason.EncodeError.t()}
  @type delete_order_response ::
          :ok | {:error, :file.posix() | Jason.DecodeError.t() | Jason.EncodeError.t()}
  @type list_syndicates_response ::
          {:ok, [Syndicate.t()]} | {:error, :file.posix() | Jason.DecodeError.t()}
  @type list_active_syndicates_response ::
          {:ok, [Syndicate.t()]} | {:error, :file.posix() | Jason.DecodeError.t()}
end
