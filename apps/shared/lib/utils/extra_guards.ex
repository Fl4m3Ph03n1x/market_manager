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

  @spec is_valid_order_type(Macro.t()) :: Macro.t()
  defguard is_valid_order_type(value) when is_binary(value) and value in ["buy", "sell"]

  @spec is_valid_subtype(Macro.t()) :: Macro.t()
  defguard is_valid_subtype(value) when is_binary(value) and value in ["regular", "atagraph"]
end
