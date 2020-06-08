defmodule MarketManager do
  @moduledoc """
  Documentation for MarketManager.
  """

  alias MarketManager.Implementation

  defdelegate activate(syndicate), to: Implementation

  defdelegate deactivate(syndicate), to: Implementation
end
