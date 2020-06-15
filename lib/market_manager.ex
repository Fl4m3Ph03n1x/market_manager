defmodule MarketManager do
  @moduledoc """
  Documentation for MarketManager.
  """

  alias MarketManager.Interpreter

  defdelegate activate(syndicate), to: Interpreter

  defdelegate deactivate(syndicate), to: Interpreter
end
