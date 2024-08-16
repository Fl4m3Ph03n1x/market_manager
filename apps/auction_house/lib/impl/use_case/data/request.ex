defmodule AuctionHouse.Impl.UseCase.Data.Request do
  @moduledoc """
  Represents a request made to a third party.
  The `args` field should contain the parameters necessary for the function call.
  """

  use TypedStruct

  alias AuctionHouse.Impl.UseCase.Data.Metadata

  @type args :: map()

  typedstruct enforce: true do
    @typedoc "Represents a Request to be made to a 3rd party."

    field(:metadata, Metadata.t())
    field(:args, map(), default: %{})
  end

  @spec new(Metadata.t(), args :: map()) :: __MODULE__.t()
  def new(meta, args \\ %{}) when is_struct(meta, Metadata) and is_map(args),
    do: %__MODULE__{
      metadata: meta,
      args: args
    }

  @spec put_arg(__MODULE__.t(), key :: atom(), value :: any()) :: __MODULE__.t()
  def put_arg(request, key, val) when is_struct(request, __MODULE__) and is_atom(key),
    do: %{request | args: Map.put(request.args, key, val)}

  @spec finish(__MODULE__.t()) :: __MODULE__.t()
  def finish(request) when is_struct(request, __MODULE__),
    do: %{request | metadata: Metadata.mark_to_send(request.metadata)}
end
