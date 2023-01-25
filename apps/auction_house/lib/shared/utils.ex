defmodule AuctionHouse.Shared.Utils do
  alias Morphix

  @spec string_map_to_struct(string_map :: map(), struct :: module()) ::
          {:ok, module()} | {:error, any()}
  def string_map_to_struct(string_map, target_struct) do
    case Morphix.atomorphiform(string_map) do
      {:ok, atom_map} -> {:ok, struct(target_struct, atom_map)}
      err -> err
    end
  end

  @spec from_tagged_tuple({:ok, any()}) :: any()
  def from_tagged_tuple({:ok, data}), do: data
end
