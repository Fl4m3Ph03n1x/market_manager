defmodule WebInterface.Commands do
  def list_commands do
    [
      %{
        name: "activate"
      },
      %{
        name: "deactivate"
      }
    ]
  end
end
