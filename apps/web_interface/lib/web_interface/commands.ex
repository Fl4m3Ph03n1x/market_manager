defmodule WebInterface.Commands do
  @moduledoc """
  Contains information about the commands the web_interface understands.
  Works as a bridge between the web interface and the Manager application, which does the real work.
  """

  alias Manager
  alias Manager.Type, as: ManagerTypes
  alias WebInterface.Syndicates

  @default_deps %{
    manager: Manager
  }

  @type command_id :: :activate | :deactivate | :authenticate
  @type command :: %{
          name: String.t,
          description: String.t,
          id: command_id
        }
  @type dependencies :: %{manager: module}
  @type request :: %{
          command: command_id,
          strategy: ManagerTypes.strategy,
          syndicates: [ManagerTypes.syndicate]
        } | %{
          command: command_id,
          cookie: String.t,
          token: String.t
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
      },
      %{
        name: "Authenticate",
        description: "
          Saving authentication information will allow this application to make requests in your behalf.
          It is a required step for the application to work.
        ",
        id: :authenticate
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

  def execute(%{command: :authenticate, cookie: cookie, token: token}, %{manager: manager}),
    do:
      manager.authenticate(%{"cookie" => cookie, "token" => token})

  @spec get_command(atom) :: command | nil
  def get_command(id),
    do:
      list_commands()
      |> Enum.filter(&by_command_id(&1, id))
      |> List.first()

  @spec by_command_id(command, atom) :: boolean
  defp by_command_id(%{id: command_id}, id), do: command_id == id
end
