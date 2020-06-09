defmodule MarketManager.CLI do
  @moduledoc """
  synopsis:
    Manages sell orders in warframe.market.
  usage:
    $ ./market_manager {options}
  example:
    ./market_manager --action=activate syndicates=new_loka,red_veil
  options:
    --action=activate|deactivate        Can be either 'activate' or 'deactivate'.
                                        Activating a syndicate means placing a sell
                                        order on warframe.market for each item the
                                        syndicate has that is in the *products.json*
                                        file.
                                        Deactivating a syndicate deletes all orders
                                        in warframe.market from the given syndicate.
    --syndicates=syndicate1,syndicate2  Syndicates to be affected by the action.
  """

  alias MarketManager

  ##########
  # Public #
  ##########

  @spec main([any]) :: :ok
  def main([]), do: IO.puts(@moduledoc)

  def main([help_opt]) when help_opt == "-h", do: IO.puts(@moduledoc)

  def main(args) do
    {opts, _positional_args, errors} = parse_args(args)

    case errors do
      [] ->
        opts
        |> process_args()
        |> IO.inspect()

      _ ->
        IO.puts("Bad option:")
        IO.inspect(errors)
        IO.puts(@moduledoc)
    end
  end

  ###########
  # Private #
  ###########

  defp parse_args(args) do
    {opts, cmd_and_args, errors} =
      OptionParser.parse(args, strict: [syndicates: :string, action: :string])

    {opts, cmd_and_args, errors}
  end

  defp process_args(opts) do
    syndicates =
      opts
      |> Keyword.get(:syndicates)
      |> String.split(",")

    action = Keyword.get(opts, :action)

    process_action(action, syndicates)
  end

  defp process_action("activate", syndicates), do:
    Enum.map(syndicates, &MarketManager.activate/1)

  defp process_action("deactivate", syndicates), do:
    Enum.map(syndicates, &MarketManager.deactivate/1)

  defp process_action(action, _syndicates), do: {:error, :unknown_action, action}

end
