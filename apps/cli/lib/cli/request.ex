defmodule Cli.Request do
  @moduledoc """
  A struct representing a parsed user request. Parsed requests have not yet
  been validated and may therefore contain invalid information.
  """

  use TypedStruct

  typedstruct do
    @typedoc "A parsed user request"

    field :action,      String.t,      enforce: true
    field :syndicates,  [String.t]
    field :strategy,    String.t
  end

  @doc """
  Create a Request struct with the given enumerable.
  """
  @spec new(Enum.t) :: __MODULE__.t
  def new(fields), do: struct!(__MODULE__, fields)

end
