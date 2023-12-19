defmodule Shared.Data.Syndicate do
  @moduledoc """
  A syndicate is a party with tradable items.
  """

  use TypedStruct

  alias Shared.Utils.Structs

  @type syndicate ::
          %{
            (name :: String.t()) => String.t(),
            (id :: String.t()) => atom() | String.t(),
            (catalog :: String.t()) => [String.t()]
          }
          | [name: String.t(), id: atom(), catalog: [String.t()]]

  @derive Jason.Encoder
  typedstruct enforce: true do
    @typedoc "Syndicate details"

    field(:name, String.t())
    field(:id, atom())
    field(:catalog, [String.t()])
  end

  @spec new(syndicate()) :: __MODULE__.t()
  def new(%{"name" => name, "id" => id, "catalog" => catalog} = syndicate)
      when is_binary(name) and is_atom(id) and is_list(catalog),
      do: Structs.string_map_to_struct(syndicate, __MODULE__)

  def new(%{"name" => name, "id" => id, "catalog" => catalog})
      when is_binary(name) and is_binary(id) and is_list(catalog),
      do:
        Structs.string_map_to_struct(
          %{"name" => name, "id" => String.to_atom(id), "catalog" => catalog},
          __MODULE__
        )

  def new([name: name, id: id, catalog: catalog] = syndicate)
      when is_binary(name) and is_atom(id) and is_list(catalog),
      do: struct(__MODULE__, syndicate)
end
