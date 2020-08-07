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

  require Logger

  ##########
  # Public #
  ##########

  @spec main([String.t]) :: :ok
  def main([]), do: Logger.info(@moduledoc)

  def main([help_opt]) when help_opt == "-h", do: Logger.info(@moduledoc)

  def main(args) do
    {opts, _positional_args, errors} = parse_args(args)

    case errors do
      [] ->
        opts
        |> process_args()
        |> log_result()

      _ ->
        log_inspect(errors, :error, "Bad option:\n")
        Logger.info(@moduledoc)
    end
  end

  ###########
  # Private #
  ###########

  @spec parse_args([String.t]) :: {OptionParser.parsed, OptionParser.argv, OptionParser.errors}
  defp parse_args(args), do:
    OptionParser.parse(args, strict: [syndicates: :string, action: :string, strategy: :string])

  @spec process_args(OptionParser.parsed) ::
    [Manager.activate_response | Manager.deactivate_response]
    | {:error, :unknown_action, bad_syndicate :: String.t}
  defp process_args(opts) do
    syndicates =
      opts
      |> Keyword.get(:syndicates)
      |> String.split(",")

    action = Keyword.get(opts, :action)

    strategy =
      opts
      |> Keyword.get(:strategy)
      |> to_strategy()

    process_action(action, syndicates, strategy)
  end

  @spec process_action(String.t, [String.t], atom) ::
    [Manager.activate_response | Manager.deactivate_response]
    | {:error, :unknown_action, bad_syndicate :: String.t}
  defp process_action("activate", syndicates, strategy), do:
    Enum.map(syndicates, &Manager.activate(&1, strategy))

  defp process_action("deactivate", syndicates, _strategy), do:
    Enum.map(syndicates, &Manager.deactivate/1)

  defp process_action(action, _syndicates, _strategy), do: {:error, :unknown_action, action}

  @spec log_result(data_to_log :: any) :: (data_to_log :: any)
  defp log_result({:error, :unknown_action, action} = data) do
    Logger.error("Unknown action: #{action}")
    Logger.info(@moduledoc)
    data
  end

  defp log_result(data) do
    Logger.info("#{inspect(data)}")
    data
  end

  @spec log_inspect(data_to_inspect :: any, :error, String.t) ::
    (data_to_inspect :: any)
  defp log_inspect(data, :error, msg) do
    Logger.error("#{msg}#{inspect(data)}")
    data
  end

  defp to_strategy("top_five_average"), do: :top_five_average
  defp to_strategy("top_three_average"), do: :top_three_average
  defp to_strategy("equal_to_lowest"), do: :equal_to_lowest
  defp to_strategy("lowest_minus_one"), do: :lowest_minus_one
  defp to_strategy(nil), do: nil
end
