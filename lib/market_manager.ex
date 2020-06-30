defmodule MarketManager do
  @moduledoc """
  Documentation for MarketManager.
  """

  alias MarketManager.Interpreter

  def activate(syndicate), do: Interpreter.activate(syndicate)

  def deactivate(syndicate), do: Interpreter.deactivate(syndicate)
end
