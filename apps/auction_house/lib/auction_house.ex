defmodule AuctionHouse do
  @moduledoc """
  Library representing the interface for the auction house.
  Responsible for making calls and decoding the answers from the auction house
  into a format the manager understands.
  """

  alias AuctionHouse.Runtime.Server
  alias AuctionHouse.Type
  alias Shared.Data.{Authorization, Credentials, Order, User}
  alias Supervisor

  #######
  # API #
  #######

  @doc """
  Places an order in warframe market.

  Example:
  ```
  alias Shared.Data.Order
  order = Order.new(%{
    "item_id" => "54e644ffe779897594fa68cd",
    "mod_rank" => 0,
    "order_type" => "sell",
    "platinum" => 20,
    "quantity" => 1
  })

  > AuctionHouse.place_order(order)
  {:ok, "626127cbc984ac033cd2bbd2"}

  > AuctionHouse.place_order(order)
  {:error, :reason, order}
  ```
  """
  @spec place_order(Order.t()) :: Type.place_order_response()
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
  The item's name is in human readable format. This function also converts the
  name into a format that the external party can understand.

  Example:
  ```
  item_name = "Despoil"

  > AuctionHouse.get_all_orders(item_name)
  {:ok, [
    %Shared.Data.OrderInfo{
          "visible" => true,
          "order_type" => "sell",
          "platform" => "pc",
          "platinum" => 20,
          "user" => %Shared.Data.OrderInfo.User{
            "ingame_name" => "user_name_1",
            "status" => "ingame"
          }
        }
      ]
  }

  > AuctionHouse.get_all_orders(item_name)
  {:error, :reason, item_name}
  ```
  """
  @spec get_all_orders(Type.item_name()) :: Type.get_all_orders_response()
  defdelegate get_all_orders(item_name), to: Server

  @doc """
  Stores the user's credentials and  authenticates with the auction house to
  make requests. Must be invoked every time the application is launched.
  It also performs the necessary steps for authorization. Returns user
  information.

  Example:
  ```
  alias Shared.Data.{Authorization, Credentials, User}
  credentials = Credentials.new("the_username", "the_password")

  > AuctionHouse.login(credentials)
  {:ok,
    {
      %Authorization{cookie: "a_cookie", token: "a_token"},
      %User{patreon?: false, ingame_name: "fl4m3"}
    }
  }

  > AuctionHouse.login(credentials)
  {:error, :reason, credentials}
  ```
  """
  @spec login(Credentials.t()) :: Type.login_response()
  defdelegate login(credentials), to: Server

  @doc """
  Feeds the authorization information directly to the AuctionHouse. Used when
  the login data is being recovered from a past login. Will only fail if this
  service is down.

  Example:
  ```
  alias Shared.Data.{Authorization, User}
  auth = Authorization.new("a_cookie", "a_token")
  user = User.new("fl4m3", false)

  > AuctionHouse.recover_login(auth, user)
  :ok
  ```
  """
  @spec recover_login(Authorization.t(), User.t()) :: Type.recover_login_response()
  defdelegate recover_login(auth, user), to: Server

  @doc false
  @spec child_spec(any) :: Supervisor.child_spec()
  defdelegate child_spec(args), to: Server
end
