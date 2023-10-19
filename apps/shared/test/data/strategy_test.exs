defmodule Shared.Data.StrategyTest do
  @moduledoc false

  use ExUnit.Case

  alias Shared.Data.Strategy

  test "new/1 returns a Strategy" do
    assert Strategy.new(%{
             "name" => "Top 5 Average",
             "id" => :top_5_average,
             "description" => "Returns the average of the top 5 items."
           }) ==
             %Strategy{
               name: "Top 5 Average",
               id: :top_5_average,
               description: "Returns the average of the top 5 items."
             }

    assert Strategy.new(
             name: "Top 5 Average",
             id: :top_5_average,
             description: "Returns the average of the top 5 items."
           ) == %Strategy{
             name: "Top 5 Average",
             id: :top_5_average,
             description: "Returns the average of the top 5 items."
           }
  end
end
