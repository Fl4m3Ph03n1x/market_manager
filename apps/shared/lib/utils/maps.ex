defmodule Shared.Utils.Maps do
  @moduledoc """
  Set of utility functions used across the app to help with Map operations.
  """

  @doc """
  Converts a string map to an atom map. Only goes 1 level deep and is not
  recursive.
  """
  @spec to_string_map(%{atom => any}) :: %{String.t() => any}
  def to_string_map(data), do: Map.new(data, fn {k, v} -> {Atom.to_string(k), v} end)
end
