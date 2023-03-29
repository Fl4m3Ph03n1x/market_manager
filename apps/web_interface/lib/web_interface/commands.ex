defmodule WebInterface.Commands do
  @moduledoc """
  Contains information about the commands the web_interface understands.
  Works as a bridge between the web interface and the Manager application, which does the real work.
  """

  alias Manager
  alias Manager.Type, as: ManagerTypes
  alias Shared.Data.Credentials
  alias WebInterface.Syndicates

  @default_deps %{
    manager: Manager
  }

  @type command_id :: :activate | :deactivate | :login

  @type command :: %{
          name: String.t(),
          description: String.t(),
          id: command_id
        }

  @type dependencies :: %{manager: module}

  @type activate_request :: %{
          command: :activate,
          strategy: ManagerTypes.strategy(),
          syndicates: [ManagerTypes.syndicate()]
        }

  @type deactivate_request :: %{
          command: :deactivate,
          syndicates: [ManagerTypes.syndicate()]
        }

  @type login_request :: %{
          command: :login,
          email: String.t(),
          password: String.t()
        }

  @type request :: activate_request | deactivate_request | login_request

  @spec list_commands :: [command]
  def list_commands,
    do: [
      %{
        name: "Activate",
        description: "
          Activating a syndicate will cause the app to create a sell order on warframe.market for each product of the said syndicate.
          The prices of each item will be determined according to a strategy that you can define.
        ",
        id: :activate
      },
      %{
        name: "Deactivate",
        description: "
          Deactivating a syndicate removes all sell orders from warframe.market for the given syndicate.
        ",
        id: :deactivate
      },
      %{
        name: "Login",
        description: "
          Log in with your Warframe Market information. This is saved locally and only used to make requests to the website.
          It is a required step for the application to work.
        ",
        id: :login
      }
    ]

  @spec execute(request, dependencies) :: any
  def execute(command, deps \\ @default_deps)

  def execute(
        %{command: :activate, strategy: strategy, syndicates: syndicates},
        %{manager: manager}
      ),
      do:
        syndicates
        |> Enum.map(&Syndicates.get_id/1)
        |> Enum.map(&manager.activate(&1, strategy))

  def execute(%{command: :deactivate, syndicates: syndicates}, %{manager: manager}),
    do:
      syndicates
      |> Enum.map(&Syndicates.get_id/1)
      |> Enum.map(&manager.deactivate/1)

  def execute(
        %{command: :login, email: email, password: password, keep_logged_in: keep_logged_in},
        %{manager: manager}
      ),
      do:
        email
        |> Credentials.new(password)
        |> manager.login(keep_logged_in)

  @spec get_command(atom) :: command | nil
  def get_command(id),
    do:
      list_commands()
      |> Enum.filter(&by_command_id(&1, id))
      |> List.first()

  @spec by_command_id(command, atom) :: boolean
  defp by_command_id(%{id: command_id}, id), do: command_id == id
end
