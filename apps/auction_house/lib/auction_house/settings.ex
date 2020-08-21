defmodule AuctionHouse.Settings do
  @moduledoc """
  Holds configurations that do not depend on the environment. 12 factor app
  standard states that only configurations that depend on the environment should
  be configurable in config files (config folder).

  Since these variables are all compile time, no matter the environment they are
  used for, this module will hold them.
  """

  @doc """
  Returns the name of the throttling queue used to make requests to
  warframe.market.
  """
  @spec requests_queue :: atom
  def requests_queue, do: :warframe_market_outgoing_requests_queue
end
