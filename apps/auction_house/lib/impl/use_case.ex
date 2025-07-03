defmodule AuctionHouse.Impl.UseCase do
  @moduledoc """
  Represents an action a user takes against the auction house's API, such as creating an order or checking user info.
  Each action has a start and a finish, with possibly many steps in the middle. This behaviour only cares about the
  first and the last, so other modules are notified when an user action starts or finishes.

  Uses structures to encode the format of requests and responses being passed around the flow.
  """

  alias AuctionHouse.Impl.UseCase.Data.{Request, Response}

  @doc """
  Starts a use case, by passing in a Request. This Request will then be used to make a request to a 3rd party library
  that will communicate with the auction house's API. The start function may call directly the finish function, or
  may call another function if the flow is more complex, which will then eventually call `finish`.
  """
  @callback start(Request.t()) :: :ok

  @doc """
  The last function to be called on a UseCase, marking the end of such. Once this function is invoked, no followups are
  allowed and the process running it will notify the interested parties (see Metadata.notify) of the result.
  """
  @callback finish(Response.t()) :: any()
end
