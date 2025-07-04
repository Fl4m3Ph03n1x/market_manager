defmodule Store.Type do
  @moduledoc """
  Contains the types for the Store library.
  Because we separate this file from the API and implementation, we also avoid
  a cyclical dependency between them.
  """

  alias Jason
  alias Shared.Data.{Authorization, Product, Strategy, Syndicate, User}

  ##########
  # Types  #
  ##########

  @type dependencies :: map()

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
          | {:error,
             :file.posix() | Jason.DecodeError.t() | {:syndicate_not_found, [Syndicate.id()]}}
  @type get_product_by_id_response ::
          {:ok, Product.t()}
          | {:error, :product_not_found | :file.posix() | Jason.DecodeError.t()}
  @type list_syndicates_response ::
          {:ok, [Syndicate.t()]} | {:error, :file.posix() | Jason.DecodeError.t()}
  @type activate_syndicates_response :: :ok | {:error, :file.posix() | Jason.DecodeError.t()}
  @type deactivate_syndicates_response :: :ok | {:error, :file.posix() | Jason.DecodeError.t()}
  @type list_active_syndicates_response ::
          {:ok, %{Syndicate.id() => Strategy.id()}}
          | {:error, :file.posix() | Jason.DecodeError.t()}
end
