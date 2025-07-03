defmodule AuctionHouse.Impl.UseCase.Data.Metadata do
  @moduledoc """
  Data about the Request or Response being made.
  Includes information important for 3rd party modules to use but that is not related to the arguments of the flow
  itself.

  Used mostly to notify interested parties of the results of the flow.
  When the flow is done, the "send?" field should be set to `true` so the handler know it has to send the results back
  to the interested parties.
  """

  use TypedStruct

  @type operation :: atom()
  @type notify :: [pid()]
  @type send? :: boolean()

  typedstruct enforce: true do
    @typedoc "Represents metadata about the request/response."

    field(:send?, boolean(), default: false)
    field(:operation, atom())
    field(:notify, [pid()])
  end

  @spec new(operation(), notify(), send?()) :: __MODULE__.t()
  def new(operation, notify, send? \\ false)
      when is_atom(operation) and is_list(notify) and is_boolean(send?),
      do: %__MODULE__{
        operation: operation,
        notify: notify,
        send?: send?
      }

  @spec mark_to_send(__MODULE__.t()) :: __MODULE__.t()
  def mark_to_send(meta) when is_struct(meta, __MODULE__), do: %{meta | send?: true}
end
