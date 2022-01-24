defmodule AuctionHouse do
  @moduledoc """
  Librabry representing the interface for the auction house.
  Responsible for making calls and decoding the answers from the auction house
  into a format the manager understands.
  """

  alias AuctionHouse.Server
  alias AuctionHouse.Type

  #######
  # API #
  #######

  @spec place_order(Type.order) :: Type.place_order_response
  defdelegate place_order(order), to: Server

  @spec delete_order(Type.order_id) :: Type.delete_order_response
  defdelegate delete_order(order_id), to: Server

  @spec get_all_orders(Type.item_name) :: Type.get_all_orders_response
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
