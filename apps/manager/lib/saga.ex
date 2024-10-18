defmodule Manager.Saga do
  @moduledoc """
  Orchestration based Sagas for complex use cases. Since the AuctionHouse is mostly asynchronous, this means some
  operations are separated by time. In order to have the asynchronous behaviour and logic in one coherent place I am
  using the Saga patter as described by Peter Ullrich: https://peterullrich.com/saga-pattern-in-elixir

  I implement each Saga using a Genserver which is spawned by a dynamic supervisor. This way I keep both runtime and
  implementation details together in one coherent place.
  """
end
