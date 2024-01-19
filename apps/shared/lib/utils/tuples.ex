defmodule Shared.Utils.Tuples do
  @moduledoc """
  Set of utility functions used across the app to help with Tuple operations.
  """

  @doc """
  Places the given data into an OK tagged tuple.
  """
  @spec to_tagged_tuple(data :: any) :: {:ok, data :: any}
  def to_tagged_tuple(data), do: {:ok, data}

  @doc """
  Retrieves the data from a given OK tagged tuple.
  """
  @spec from_tagged_tuple({:ok, data :: any}) :: data :: any
  def from_tagged_tuple({:ok, data}), do: data

  @doc """
  Returns whether or not a tagged tuple is of type OK.
  """
  @spec ok?({atom, any}) :: boolean
  def ok?({:ok, _data}), do: true
  def ok?({_tag, _data}), do: false
end
