defmodule Shared.Utils.Tuples do
  @moduledoc """
  Set of functions used across the app, for utility purposes, like dealing with
  tuples, maps and other data structures.
  """

  @spec from_tagged_tuple({:ok, any}) :: any
  def from_tagged_tuple({:ok, data}), do: data

  @spec is_ok?({atom, any}) :: boolean
  def is_ok?({:ok, _data}), do: true
  def is_ok?({_tag, _data}), do: false
end
