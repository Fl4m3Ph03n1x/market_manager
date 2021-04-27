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
      },
      %{
        name: "New Loka",
        id: :new_loka
      },
      %{
        name: "Arbiters of Hexis",
        id: :arbiters_of_hexis
      },
      %{
        name: "Steel Meridian",
        id: :steel_meridian
      },
      %{
        name: "Cephalon Suda",
        id: :cephalon_suda
      },
      %{
        name: "Cephalon Simaris",
        id: :simaris
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
