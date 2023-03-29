defmodule Shared.Utils.Structs do
  @moduledoc """
  Set of utility functions used across the app to help with Struct operations.
  """

  alias Morphix

  @doc """
  Converts given string map into the given struct.
  """
  @spec string_map_to_struct(
          data :: map,
          target_struct :: module | struct
        ) ::
          target_struct :: struct
  def string_map_to_struct(data, target_struct) do
    data
    |> Morphix.atomorphiform!()
    |> data_to_struct(target_struct)
  end

  @doc """
  Converts the given enumerable into teh given struct.
  """
  @spec data_to_struct(data :: Enumerable.t(), target_struct :: module | struct) ::
          target_struct :: struct
  def data_to_struct(data, target_struct), do: struct(target_struct, data)
end
