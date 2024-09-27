defmodule AuctionHouse do
  @moduledoc """
  Library representing the interface for the auction house.
  Responsible for making calls and decoding the answers from the auction house
  into a format the manager understands.
  """

  alias AuctionHouse.Runtime.{AuctionSupervisor, Server}
  alias AuctionHouse.Type
  alias Shared.Data.{Authorization, Credentials, Order, PlacedOrder, User}
  alias Supervisor

  #######
  # API #
  #######

  @doc """
  Places an order in warframe market.
  Notifies invoking process asynchronously with placed order or with error.

  Example:
  ```
  > alias Shared.Data.{Order, PlacedOrder}
  > order = Order.new(%{
    "item_id" => "54e644ffe779897594fa68cd",
    "mod_rank" => 0,
    "order_type" => "sell",
    "platinum" => 20,
    "quantity" => 1
  })

  > AuctionHouse.place_order(order)
  :ok

  The received messages will one of the following formats:

  - {:place_order, {:ok, %PlacedOrder{item_id: "54a74454e779892d5e5155d5", order_id: "66b9c7aa6b17410a57974e4b"}}}
  - {:place_order, {:error, {reason, err}}}
  ```
  """
  @spec place_order(Order.t()) :: Type.place_order_response()
  defdelegate place_order(order), to: Server

  @doc """
  Deletes an order from warframe market asynchronously.
  Notifies invoking process asynchronously with placed order or with error.

  Example:
  ```
  > alias Shared.Data.PlacedOrder
  > placed_order = PlacedOrder.new(%{
      "item_id" => "54e644ffe779897594fa68cd",
      "order_id" => "626127cbc984ac033cd2bbd2"
  })

  > AuctionHouse.delete_order(placed_order)
  :ok

  The received messages will one of the following formats:

  - {:delete_order, {:ok, %PlacedOrder{item_id: "54e644ffe779897594fa68cd", order_id: "626127cbc984ac033cd2bbd2"}}}
  - {:place_order, {:error, {reason, err}}}
  ```
  """
  @spec delete_order(PlacedOrder.t()) :: Type.delete_order_response()
  defdelegate delete_order(order_id), to: Server

  @doc """
  Gets all warframe market orders for the item with the given name.
  The item's name is in human readable format. This function also converts the
  name into a format that the external party can understand.
  Notifies invoking process asynchronously with a list of OrderInfo or with error.

  Example:
  ```
  > alias Shared.Data.OrderInfo
  > item_name = "Despoil"

  > AuctionHouse.get_item_orders(item_name)
  > :ok

  The received messages will one of the following formats:

  - {:get_item_orders,  {:ok, [%OrderInfo{"visible" => true, "order_type" => "sell", "platform" => "pc",
    "platinum" => 20, "user" => %OrderInfo.User{"ingame_name" => "user_name_1", "status" => "ingame"}}]}
  - {:get_item_orders, {:error, {reason, err}}}
  ```
  """
  @spec get_item_orders(Type.item_name()) :: Type.get_item_orders_response()
  defdelegate get_item_orders(item_name), to: Server

  @doc """
  Gets all warframe market sell orders for the given user.
  Notifies invoking process asynchronously with a list of user PlacedOrders or with error.

  Example:
  ```
  > AuctionHouse.get_user_orders("Fl4m3")
  > :ok

  The received messages will one of the following formats:

  - {:get_user_orders, {:ok,
    [
      %PlacedOrder{
        order_id: "66058313a9630600302d4889",
        item_id: "55108594e77989728d5100c6"
      },
      %PlacedOrder{
        order_id: "6605832ea96306003657a90d",
        item_id: "54e644ffe779897594fa68d2"
      }
    ]
  }}

  - {:get_user_orders, {:error, {reason, err}}}
  ```
  """
  @spec get_user_orders(Type.username()) :: Type.get_user_orders_response()
  defdelegate get_user_orders(username), to: Server

  @doc """
  Authenticates the user with the auction house and saves the session.
  Must be invoked every time the application is launched.
  Notifies invoking process asynchronously with user information or with error.

  Example:
  ```
  > alias Shared.Data.{Authorization, Credentials, User}
  > credentials = Credentials.new("the_username", "the_password")

  > AuctionHouse.login(credentials)
  :ok

  The received messages will one of the following formats:

  - {:login, {:ok, { %Authorization{cookie: "a_cookie", token: "a_token"}, %User{patreon?: false, ingame_name: "fl4m3"}}}}
  - {:login, {:error, {reason, err}}}

  ```
  """
  @spec login(Credentials.t()) :: Type.login_response()
  defdelegate login(credentials), to: Server

  @doc """
  Feeds the authorization information directly to the AuctionHouse. Used when
  the login data is being recovered from a past login to update the this service's state.
  Will only fail if this service is down.

  Example:
  ```
  > alias Shared.Data.{Authorization, User}
  > auth = Authorization.new("a_cookie", "a_token")
  > user = User.new("fl4m3", false)

  > AuctionHouse.update_login(auth, user)
  :ok
  ```
  """
  @spec update_login(Authorization.t(), User.t()) :: Type.update_login_response()
  defdelegate update_login(auth, user), to: Server

  @doc """
  Deletes the current session and user data from the this application.
  Does not interact with the External AuctionHouse, this is a local operation only.
  Will only fail if this service is down.

  Example:
  ```
  > AuctionHouse.logout()
  :ok
  ```
  """
  @spec logout :: Type.logout_response()
  defdelegate logout, to: Server

  @doc false
  @spec child_spec(any) :: Supervisor.child_spec()
  defdelegate child_spec(args), to: AuctionSupervisor
end
