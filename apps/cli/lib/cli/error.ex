defmodule Cli.Error do
  @moduledoc """
  A struct representing an error. The error here can be of any type and from any
  level of the application. This struct is merely how the Cli app views and
  understands errors. All errors must conform to this struct.
  """

  alias Recase

  use TypedStruct

  typedstruct do
    @typedoc "An error"

    field :type,  atom,     enforce: true
    field :input, String.t, enforce: true
  end

  ##########
  # Public #
  ##########

  @doc """
  Create an Error struct with the given enumerable.
  """
  @spec new(Enum.t) :: __MODULE__.t
  def new(fields), do: struct!(__MODULE__, fields)

  @doc """
  Converts the given Error struct to a String a human user is capable of
  understanding.
  """
  @spec to_string(__MODULE__.t) :: String.t
  def to_string(%__MODULE__{type: err_type, input: usr_input}), do:
    err_type
    |> Atom.to_string()
    |> Recase.to_sentence()
    |> append_data(usr_input)

  ###########
  # Private #
  ###########

  @spec append_data(sentence :: String.t, input:: String.t) :: (result :: String.t)
  defp append_data(sentence, user_input), do: sentence <> ": " <> user_input

end
