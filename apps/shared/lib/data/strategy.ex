defmodule Shared.Data.Strategy do
  @moduledoc """
  A strategy for selling a product.
  """

  use TypedStruct

  alias Shared.Utils.Structs

  @type name :: String.t()
  @type id :: atom()
  @type description :: String.t()

  @type strategy ::
          %{
            (name :: String.t()) => String.t(),
            (id :: String.t()) => atom(),
            (description :: String.t()) => String.t()
          }
          | [name: String.t(), id: atom(), description: String.t()]

  @derive Jason.Encoder
  typedstruct enforce: true do
    @typedoc "Strategy details"

    field(:name, name())
    field(:id, id())
    field(:description, description())
  end

  @spec new(strategy()) :: __MODULE__.t()
  def new(%{"name" => name, "id" => id, "description" => description} = strategy)
      when is_binary(name) and is_atom(id) and is_binary(description),
      do: Structs.string_map_to_struct(strategy, __MODULE__)

  def new([name: name, id: id, description: description] = strategy)
      when is_binary(name) and is_atom(id) and is_binary(description),
      do: struct(__MODULE__, strategy)
end
