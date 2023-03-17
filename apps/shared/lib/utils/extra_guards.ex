defmodule Shared.Utils.ExtraGuards do
  @moduledoc """
  Contains additional guards to use in functions.
  """

  @spec is_pos_integer(Macro.t()) :: Macro.t()
  defguard is_pos_integer(value) when is_integer(value) and value > 0

  @spec is_non_neg_integer(Macro.t()) :: Macro.t()
  defguard is_non_neg_integer(value) when is_integer(value) and value >= 0

  @spec is_non_neg_number(Macro.t()) :: Macro.t()
  defguard is_non_neg_number(value) when is_number(value) and value >= 0

  @spec is_pos_number(Macro.t()) :: Macro.t()
  defguard is_pos_number(value) when is_number(value) and value > 0
end
