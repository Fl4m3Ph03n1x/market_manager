defmodule Manager.Type do
  @moduledoc """
  Holds the types for the Manager library.
  """

  alias Shared.Data.{Strategy, Syndicate, User}

  ##########
  # Types  #
  ##########

  @type item_id :: String.t()
  @type handle :: (result :: any -> :ok)
  @type dependencies :: %{store: module(), auction_house: module()}

  #############
  # Responses #
  #############

  @type activate_response :: :ok
  @type deactivate_response :: :ok
  @type login_response :: :ok
  @type recover_login_response :: {:ok, User.t() | nil} | {:error, any}
  @type logout_response :: :ok | {:error, any}
  @type syndicates_response :: {:ok, [Syndicate.t()]} | {:error, any}
  @type active_syndicates_response :: {:ok, [Syndicate.t()]} | {:error, any}
  @type strategies_response :: {:ok, [Strategy.t()]} | {:error, any}
end
