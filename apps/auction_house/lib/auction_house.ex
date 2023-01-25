defmodule AuctionHouse do
  @moduledoc """
  Librabry representing the interface for the auction house.
  Responsible for making calls and decoding the answers from the auction house
  into a format the manager understands.
  """

  alias AuctionHouse.Data
  alias AuctionHouse.Runtime.Server
  alias AuctionHouse.Type
  alias Supervisor

  #######
  # API #
  #######

  @doc """
  Places an order in warframe market.

  Example:
  ```
  order = %{
    "item_id" => "54e644ffe779897594fa68cd",
    "mod_rank" => 0,
    "order_type" => "sell",
    "platinum" => 20,
    "quantity" => 1
  }

  > AuctionHouse.place_order(order)
  {:ok, "626127cbc984ac033cd2bbd2"}

  > AuctionHouse.place_order(order)
  {:error, :reason, order}
  ```
  """
  @spec place_order(Type.order()) :: Type.place_order_response()
  defdelegate place_order(order), to: Server

  @doc """
  Deletes an order from warframe market.

  Example:
  ```
  order_id = "626127cbc984ac033cd2bbd2"

  > AuctionHouse.delete_order(order_id)
  {:ok, order_id}

  > AuctionHouse.delete_order(order_id)
  {:error, :reason, order_id}
  ```
  """
  @spec delete_order(Type.order_id()) :: Type.delete_order_response()
  defdelegate delete_order(order_id), to: Server

  @doc """
  Gets all warframe market orders for the item with the given name.
  The itema name is in human readable format. This function also converts the
  name into a format that the external party can understand.

  Example:
  ```
  item_name = "Despoil"

  > AuctionHouse.get_all_orders(item_name)
  {:ok, [%{
          "visible" => true,
          "order_type" => "sell",
          "platform" => "pc",
          "platinum" => 20,
          "user" => %{
            "ingame_name" => "usern_name_1",
            "status" => "ingame"
          }
        }]
  }

  > AuctionHouse.get_all_orders(item_name)
  {:error, :reason, item_name}
  ```
  """
  @spec get_all_orders(Type.item_name()) :: Type.get_all_orders_response()
  defdelegate get_all_orders(item_name), to: Server

  @doc """
  Stores the user's credentials and  authenticates with the auction house to
  make requests. Must be invoked everytime the applciation is launched.
  It also performs the necessary steps for authorization.

  Example:
  ```
  access_info = %{
    "username" => "username",
    "password" => "password"
  }

  > AuctionHouse.login(credentials)
  {:ok, access_info}
  ```
  """
  @spec login(Data.credentials()) :: Type.login_response()
  defdelegate login(credentials), to: Server

  @doc false
  @spec child_spec(any) :: Supervisor.child_spec()
  defdelegate child_spec(args), to: Server
end
