defmodule Shared.Data.SyndicateTest do
  @moduledoc false

  use ExUnit.Case, async: true

  alias Shared.Data.Syndicate

  test "new/1 returns a Syndicate" do
    assert Syndicate.new(%{"name" => "Red Veil", "id" => :red_veil, "catalog" => []}) ==
             %Syndicate{name: "Red Veil", id: :red_veil, catalog: []}

    assert Syndicate.new(%{"name" => "Red Veil", "id" => "red_veil", "catalog" => []}) ==
             %Syndicate{name: "Red Veil", id: :red_veil, catalog: []}

    assert Syndicate.new(name: "Red Veil", id: :red_veil, catalog: []) ==
             %Syndicate{name: "Red Veil", id: :red_veil, catalog: []}
  end
end
