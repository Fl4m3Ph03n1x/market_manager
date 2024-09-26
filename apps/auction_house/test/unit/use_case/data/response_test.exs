defmodule AuctionHouse.Impl.UseCase.Data.ResponseTest do
  @moduledoc false

  use ExUnit.Case, async: true

  alias AuctionHouse.Impl.UseCase.Data.{Metadata, Response}

  test "returns a new struct" do
    meta = %Metadata{
      operation: :login,
      notify: [],
      send?: false
    }

    assert Response.new(meta, "{}", %{"Application" => "json"}) ==
             %Response{
               metadata: meta,
               body: "{}",
               headers: %{"Application" => "json"},
               request_args: %{}
             }

    assert Response.new(meta, "{}", %{"Application" => "json"}, %{a: 1}) ==
             %Response{
               metadata: meta,
               body: "{}",
               headers: %{"Application" => "json"},
               request_args: %{a: 1}
             }
  end
end
