defmodule Shared.Data.Syndicate do
  @moduledoc """
  A syndicate is a party with tradable items.
  """

  use TypedStruct

  alias Shared.Utils.Structs

  @type syndicate ::
          %{
            (name :: String.t()) => String.t(),
            (id :: String.t()) => atom(),
          } | [name: String.t(), id: atom()]

  @derive Jason.Encoder
  typedstruct enforce: true do
    @typedoc "Syndicate details"

    field(:name, String.t())
    field(:id, atom())
  end

  @spec new(syndicate()) :: __MODULE__.t()
  def new(%{"name" => name, "id" => id } = syndicate) when is_binary(name) and is_atom(id), do:
    Structs.string_map_to_struct(syndicate, __MODULE__)

  def new([name: name, id: id] = syndicate) when is_binary(name) and is_atom(id), do: struct(__MODULE__, syndicate)
end
