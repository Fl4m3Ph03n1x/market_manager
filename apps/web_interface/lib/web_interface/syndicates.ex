defmodule WebInterface.Syndicates do
  @moduledoc """
  Contains information about the available syndicates that Manager supports as well as utility functions
  to work with them.
  """

  alias Manager

  @type syndicate_info :: %{
          (name :: atom) => String.t(),
          (id :: atom) => Manager.syndicate()
        }

  @spec list_syndicates :: [syndicate_info]
  def list_syndicates,
    do: [
      %{
        name: "Red Veil",
        id: "red_veil"
      },
      %{
        name: "Perrin Sequence",
        id: "perrin_sequence"
      },
      %{
        name: "New Loka",
        id: "new_loka"
      },
      %{
        name: "Arbiters of Hexis",
        id: "arbiters_of_hexis"
      },
      %{
        name: "Steel Meridian",
        id: "steel_meridian"
      },
      %{
        name: "Cephalon Suda",
        id: "cephalon_suda"
      },
      %{
        name: "Cephalon Simaris",
        id: "simaris"
      }
    ]

  @spec get_syndicate(String.t()) :: syndicate_info | nil
  def get_syndicate(id),
    do:
      list_syndicates()
      |> Enum.filter(&by_id(&1, id))
      |> List.first()

  @spec by_id(syndicate_info, String.t()) :: boolean
  defp by_id(%{id: synd_id}, id), do: synd_id == id

  @spec get_id(syndicate_info) :: Manager.syndicate() | nil
  def get_id(syndicate), do: Map.get(syndicate, :id)
end
