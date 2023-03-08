defmodule Shared.Utils.ExtraGuards do
  @moduledoc """
  Contains additional guards to use in functions.
  """

  @spec is_pos_integer(any) ::
          {:__block__ | {:., [], [:andalso | :erlang, ...]}, [],
           [{:= | {any, any, any}, list, [...]}, ...]}
  defguard is_pos_integer(value) when is_integer(value) and value > 0
  defguard is_non_neg_integer(value) when is_integer(value) and value >= 0

  defguard is_non_neg_number(value) when is_number(value) and value >= 0
  defguard is_pos_number(value) when is_number(value) and value > 0
end
