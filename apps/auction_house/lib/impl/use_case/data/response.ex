defmodule AuctionHouse.Impl.UseCase.Data.Response do
  @moduledoc """
  Represents a response from a 3rd party, parsed to be more user friendly and to abstract the format of the libraries
  bellow.

  Contains the original Request arguments, for cases when knowing the original information is important.
  """

  use TypedStruct

  alias AuctionHouse.Impl.UseCase.Data.{Metadata, Request}

  @type request_args :: Request.args()
  @type body :: String.t()
  @type headers :: %{String.t() => String.t()}

  typedstruct enforce: true do
    @typedoc "A Response from a 3rd party."

    field(:metadata, Metadata.t())
    field(:request_args, map(), default: %{})
    field(:body, String.t())
    field(:headers, %{String.t() => String.t()})
  end

  @spec new(Metadata.t(), body(), headers(), request_args()) :: __MODULE__.t()
  def new(meta, body, headers, request_args \\ %{})
      when is_struct(meta, Metadata) and is_binary(body) and is_map(headers) and
             is_map(request_args),
      do: %__MODULE__{
        metadata: meta,
        body: body,
        headers: headers,
        request_args: request_args
      }
end
