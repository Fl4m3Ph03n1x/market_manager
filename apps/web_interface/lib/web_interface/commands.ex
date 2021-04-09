defmodule WebInterface.Commands do

  def list_commands, do:
    [
      %{
        name: "Activate",
        description: "
          Activating a syndicate will cause the app to create a sell order on warframe.market for each product of the said syndicate.
          The prices of each item will be determined accoring to a strategy that you can define.
        "
      },
      %{
        name: "Deactivate",
        description: "
          Deactivating a syndicate removes all sell orders from waframe.market for the given syndicate.
        "
      }
    ]


  def get_command(name), do:
    list_commands()
    |> Enum.filter(&by_command_name(&1, name))
    |> hd()

  defp by_command_name(%{name: cname}, name), do: cname == name

end
