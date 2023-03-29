defmodule Manager.Type do
  @moduledoc """
  Holds the types for the Manager library.
  """

  ##########
  # Types  #
  ##########

  @type syndicate :: String.t()
  @type strategy :: :top_five_average | :top_three_average | :equal_to_lowest | :lowest_minus_one
  @type error_reason :: atom
  @type item_id :: String.t()
  @type handle :: (result :: any -> :ok)
  @type dependencies :: keyword(module)

  #############
  # Responses #
  #############

  @type activate_response :: :ok
  @type deactivate_response :: :ok
  @type login_response :: :ok
end
