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

  alias Recase

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
  @spec main(args, dependecies) :: :ok
  def main(args, deps \\ @default_deps)

  def main([], _deps), do: Logger.info(@moduledoc)

  def main([help_opt], _deps) when help_opt == "-h", do: Logger.info(@moduledoc)

  def main(args, %{manager: manager}) do
    {opts, _positional_args, errors} = parse_args(args)

    case errors do
      [] ->
        opts
        |> process_args(manager)
        |> log_result()

      _ ->
        log_inspect(errors, :error, "Bad option:\n")
        Logger.info(@moduledoc)
    end
  end

  ###########
  # Private #
  ###########

  @spec parse_args(args) :: {OptionParser.parsed, OptionParser.argv, OptionParser.errors}
  defp parse_args(args), do:
    OptionParser.parse(args, strict: [syndicates: :string, action: :string, strategy: :string])

  @spec process_args(OptionParser.parsed, module) ::
    [Manager.activate_response | Manager.deactivate_response]
    | {:error, :unknown_action, String.t}
    | {:error, :unknown_strategy, String.t}
  defp process_args(opts, manager) do
    syndicates =
      opts
      |> Keyword.get(:syndicates)
      |> String.split(",")

    action = Keyword.get(opts, :action)

    strategy =
      opts
      |> Keyword.get(:strategy)
      |> to_strategy()

    process_action(action, syndicates, strategy, manager)
  end

  @spec process_action(action, [syndicate], strategy, module) ::
    [Manager.activate_response | Manager.deactivate_response]
    | {:error, :unknown_action, String.t}
    | {:error, :unknown_strategy, String.t}
  defp process_action("activate", _syndicates, {:error, :unknown_strategy, strategy}, _manager), do:
    {:error, :unknown_strategy, strategy}

  defp process_action("activate", syndicates, strategy, manager), do:
    Enum.map(syndicates, &manager.activate(&1, strategy))

  defp process_action("deactivate", syndicates, nil, manager), do:
    Enum.map(syndicates, &manager.deactivate/1)

  defp process_action(action, _syndicates, _strategy, _manager), do: {:error, :unknown_action, action}

  @spec log_result(data_to_log :: any) :: (data_to_log :: any)
  defp log_result({:error, reason, input} = data) do
    reason
    |> Atom.to_string()
    |> Recase.to_sentence()
    |> append_data(input)
    |> Logger.error()

    Logger.info(@moduledoc)
    data
  end

  defp log_result(data) do
    Logger.info("#{inspect(data)}")
    data
  end

  @spec append_data(sentence :: String.t, input:: String.t) :: (result :: String.t)
  defp append_data(sentence, user_input), do: sentence <> ": " <> user_input

  @spec log_inspect(data_to_inspect :: any, :error, msg :: String.t) ::
    (data_to_inspect :: any)
  defp log_inspect(data, :error, msg) do
    Logger.error("#{msg}#{inspect(data)}")
    data
  end

  @spec to_strategy(String.t | nil) :: strategy
  defp to_strategy(nil), do: nil

  defp to_strategy(user_input) do
    if Manager.valid_strategy?(user_input) do
      String.to_atom(user_input)
    else
      {:error, :unknown_strategy, user_input}
    end
  end

end
