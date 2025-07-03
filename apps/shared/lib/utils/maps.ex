defmodule Shared.Utils.Maps do
  @moduledoc """
  Set of utility functions used across the app to help with Map operations.
  """

  @doc """
  Converts an atom map to a string map. Only goes 1 level deep and is not
  recursive.
  """
  @spec to_string_map(%{atom => any}) :: %{String.t() => any}
  def to_string_map(data), do: Map.new(data, fn {k, v} -> {Atom.to_string(k), v} end)

  @doc """
  Converts a string map to an atom map. Only goes 1 level deep and is not recursive.
  Converting the values only works for String type values.
  """
  @spec to_atom_map(%{String.t() => String.t()}, boolean) :: %{atom() => atom() | String.t()}
  def to_atom_map(data, convert_values? \\ false) do
    Map.new(data, fn {k, v} ->
      {String.to_atom(k),
       if convert_values? and is_binary(v) do
         String.to_atom(v)
       else
         v
       end}
    end)
  end
end
