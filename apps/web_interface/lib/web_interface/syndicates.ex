defmodule WebInterface.Syndicates do
  def list_syndicates,
    do: [
      %{
        name: "Red Veil",
        id: :red_veil
      },
      %{
        name: "Perrin Sequence",
        id: :perrin_sequence
      }
    ]

  def get_syndicate(id),
    do:
      list_syndicates()
      |> Enum.filter(&by_id(&1, id))
      |> hd()

  defp by_id(%{id: synd_id}, id), do: synd_id == id

  def get_id(syndicate), do: syndicate.id
end
