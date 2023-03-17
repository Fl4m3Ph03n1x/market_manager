defmodule Shared.Utils.Maps do
  @moduledoc """
  Set of functions used across the app, for utility purposes, like dealing with
  tuples, maps and other data structures.
  """

  @spec to_string_map(%{atom => any}) :: %{String.t() => any}
  def to_string_map(data), do: Map.new(data, fn {k, v} -> {Atom.to_string(k), v} end)
end
