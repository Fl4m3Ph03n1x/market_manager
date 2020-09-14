defmodule Cli.Parser do
  @moduledoc """
  Parses user input and transforms it into a format that CLI app can understand.
  """

  def parse(args) do
    {opts, _positional_args, errors} = OptionParser.parse(args, strict: [
      syndicates: :string,
      action: :string,
      strategy: :string,
      cookie: :string,
      token: :string
    ])

    case errors do
      [] ->
        {:ok,
          %{
            syndicates: parse_syndicates(opts),
            action: parse_action(opts),
            strategy: parse_strategy(opts)
          }
        }

      errors ->
        typed_errors = Enum.reduce(errors, [], fn ({opt, _val}, acc) ->
          [%{type: :bad_option, input: opt} | acc]
        end)

        {:error, typed_errors}
    end
  end

  defp parse_syndicates(opts), do:
    opts
    |> Keyword.get(:syndicates)
    |> String.split(",")

  defp parse_action(opts), do: Keyword.get(opts, :action)

  defp parse_strategy(opts), do: Keyword.get(opts, :strategy)
end
