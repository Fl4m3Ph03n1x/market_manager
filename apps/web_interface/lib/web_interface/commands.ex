defmodule WebInterface.Commands do

  def list_commands, do:
    [
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


  def get_command(id), do:
    list_commands()
    |> Enum.filter(&by_command_id(&1, id))
    |> hd()

  defp by_command_id(%{id: command_id}, id), do: command_id == id

end
