defmodule AuctionHouse do
  @moduledoc """
  Librabry representing the interface for the auction house.
  Responsible for making calls and decoding the answers from the auction house
  into a format the manager understands.
  """

  alias AuctionHouse.Server

  ##########
  # Types  #
  ##########

  @type item_id :: String.t
  @type item_name :: String.t
  @type order_id :: String.t

  @type order :: %{
    (item_id :: String.t) => String.t,
    (mod_rank :: String.t) => non_neg_integer | String.t,
    (order_type :: String.t) => String.t,
    (platinum :: String.t) => non_neg_integer,
    (quantity :: String.t) => non_neg_integer
  }

  @type order_info :: %{
    (visible :: String.t) => boolean,
    (order_type :: String.t) => String.t,
    (platform :: String.t) => String.t,
    (platinum :: String.t) => non_neg_integer,
    (user :: String.t) => %{
      (ingame_name :: String.t) => String.t,
      (status :: String.t) => String.t
    }
  }

  #############
  # Responses #
  #############

  @type place_order_response :: {:ok, order_id} | {:error, atom, order}
  @type delete_order_response :: {:ok, order_id} | {:error, atom, order_id}
  @type get_all_orders_response :: {:ok, [order_info]} | {:error, atom, item_name}

  #######
  # API #
  #######

  @spec place_order(order) :: place_order_response
  defdelegate place_order(order), to: Server

  @spec delete_order(order_id) :: delete_order_response
  defdelegate delete_order(order_id), to: Server

  @spec get_all_orders(item_name) :: get_all_orders_response
  defdelegate get_all_orders(item_name), to: Server

  @spec child_spec(any) :: %{
          :id => any,
          :start => {atom, atom, [any]},
          optional(:modules) => :dynamic | [atom],
          optional(:restart) => :permanent | :temporary | :transient,
          optional(:shutdown) => :brutal_kill | :infinity | non_neg_integer,
          optional(:type) => :supervisor | :worker
        }
  @doc false
  defdelegate child_spec(args), to: Server
end
