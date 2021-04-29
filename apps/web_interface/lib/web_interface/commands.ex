defmodule WebInterface.Commands do
  @moduledoc """
  Contains information about the commands the web_interface understands.
  Works as a bridge between the web interface and the Manager application, which does the real work.
  """

  alias Manager
  alias WebInterface.Syndicates

  @default_deps %{
    manager: Manager
  }

  @type command_id :: :activate | :deactivate
  @type command :: %{
          (name :: atom) => String.t(),
          (description :: atom) => String.t(),
          (id :: atom) => command_id
        }
  @type dependencies :: %{manager: module}
  @type request :: %{
          (command :: atom) => command_id,
          (strategy :: atom) => Manager.strategy(),
          (syndicates :: atom) => [Manager.syndicate()]
        }

  @spec list_commands :: [command]
  def list_commands,
    do: [
      %{
        name: "Activate",
        description: "
          Activating a syndicate will cause the app to create a sell order on warframe.market for each product of the said syndicate.
          The prices of each item will be determined accoring to a strategy that you can define.
        ",
        id: :activate
      },
      %{
        name: "Deactivate",
        description: "
          Deactivating a syndicate removes all sell orders from waframe.market for the given syndicate.
        ",
        id: :deactivate
      }
    ]

  @spec execute(request, dependencies) :: any
  def execute(command, deps \\ @default_deps)

  def execute(
        %{command: :activate, strategy: strat, syndicates: synds},
        %{manager: manager}
      ),
      do:
        synds
        |> Enum.map(&Syndicates.get_id/1)
        |> Enum.map(&manager.activate(&1, strat))

  def execute(%{command: :deactivate, syndicates: synds}, %{manager: manager}),
    do:
      synds
      |> Enum.map(&Syndicates.get_id/1)
      |> Enum.map(&manager.deactivate/1)

  @spec get_command(atom) :: command | nil
  def get_command(id),
    do:
      list_commands()
      |> Enum.filter(&by_command_id(&1, id))
      |> List.first()

  @spec by_command_id(command, atom) :: boolean
  defp by_command_id(%{id: command_id}, id), do: command_id == id
end
