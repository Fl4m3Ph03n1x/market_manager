defmodule AuctionHouse.Shared.Utils do
  @moduledoc """
  Set of functions used across the app, for utility purposes, like dealing with
  tuples, maps and other data structures.
  """

  alias Morphix

  @spec string_map_to_struct(data :: map, target_struct :: module | struct) ::
          target_struct :: struct
  def string_map_to_struct(data, target_struct) do
    data
    |> Morphix.atomorphiform!()
    |> data_to_struct(target_struct)
  end

  @spec from_tagged_tuple({:ok, any}) :: any
  def from_tagged_tuple({:ok, data}), do: data

  @spec is_ok?({atom, any}) :: boolean
  def is_ok?({:ok, _data}), do: true
  def is_ok?({_tag, _data}), do: false

  @spec data_to_struct(data :: Enumerable.t(), target_struct :: module | struct) ::
          target_struct :: struct
  def data_to_struct(data, target_struct), do: struct(target_struct, data)
end
