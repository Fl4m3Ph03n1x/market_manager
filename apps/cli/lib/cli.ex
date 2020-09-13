defmodule Cli do
  @moduledoc """
  synopsis:
    Manages sell orders in warframe.market.
  usage:
    $ ./market_manager {options}
  example:
    ./market_manager --action=activate --syndicates=new_loka,red_veil --strategy=equal_to_lowest
  options:
    --action=activate|deactivate
      Can be either 'activate' or 'deactivate'. Activating a syndicate means
      placing a sell order on warframe.market for each item the syndicate has
      that is in the *products.json* file. Deactivating a syndicate deletes all
      orders in warframe.market from the given syndicate.

    --syndicates=syndicate1,syndicate2
      Syndicates to be affected by the action.

    --strategy=top_five_average|top_three_average|equal_to_lowest|lowest_minus_one
      The strategy used by the price analysr to calculate the price at which
      your items should be sold.
  """

  alias Cli.{Parser, Validator}
  alias Recase

  use Rop

  require Logger

  @default_deps %{
    manager: Manager
  }

  @type dependecies :: %{manager: module}
  @type args :: [String.t]
  @type syndicate :: String.t
  @type action :: String.t
  @type strategy :: atom | nil | {:error, :unknown_strategy, String.t}

  ##########
  # Public #
  ##########

  @doc """
  Receives the input from the user, parses it and sends it to the Manager.
  Returns whatever response the Manager gave or an error message if the input
  was malformed.

  Can be invoked  with ["-h"] to see the help logs.
  """
  # @spec main(args, dependecies) :: :ok
  def main(args, deps \\ @default_deps)

  def main([], _deps), do: Logger.info(@moduledoc)

  def main([help_opt], _deps) when help_opt == "-h", do: Logger.info(@moduledoc)

  def main(args, %{manager: manager}), do:
    args
    |> Parser.parse()
    >>> Validator.validate(manager)
    >>> process(manager)
    |> handle_result

  ###########
  # Private #
  ###########

  defp process(%{action: "activate", strategy: strategy, syndicates: syndicates}, manager), do:
    Enum.map(syndicates, &manager.activate(&1, strategy))

  defp process(%{action: "deactivate", syndicates: syndicates}, manager), do:
    Enum.map(syndicates, &manager.deactivate/1)

  @spec handle_result(data_to_log :: any) :: (data_to_log :: any)
  defp handle_result({:error, errors} = data) do
    Enum.each(errors, &log_error/1)
    Logger.info(@moduledoc)
    data
  end

  defp handle_result(data) do
    Logger.info("#{inspect(data)}")
    data
  end

  @spec log_error(%{type: atom, input: String.t}) :: :ok
  defp log_error(%{type: err_type, input: usr_input}), do:
    err_type
    |> Atom.to_string()
    |> Recase.to_sentence()
    |> append_data(usr_input)
    |> Logger.error()

  @spec append_data(sentence :: String.t, input:: String.t) :: (result :: String.t)
  defp append_data(sentence, user_input), do: sentence <> ": " <> user_input

end
