defmodule AuctionHouse.Impl.UseCase.Data.RequestTest do
  @moduledoc false

  use ExUnit.Case, async: true

  alias AuctionHouse.Impl.UseCase.Data.{Metadata, Request}

  test "returns a new struct" do
    meta = %Metadata{
      operation: :login,
      notify: [],
      send?: false
    }

    assert Request.new(meta) ==
             %Request{
               metadata: meta,
               args: %{}
             }

    assert Request.new(meta, %{hello: "world"}) ==
             %Request{
               metadata: meta,
               args: %{hello: "world"}
             }
  end

  test "adds args to request" do
    meta = %Metadata{
      operation: :login,
      notify: [],
      send?: false
    }

    req =
      meta
      |> Request.new()
      |> Request.put_arg(:hello, "world")

    assert req == %Request{metadata: meta, args: %{hello: "world"}}
  end

  test "marks metadata to send" do
    meta = %Metadata{
      operation: :login,
      notify: [],
      send?: false
    }

    req =
      meta
      |> Request.new()
      |> Request.finish()

    assert req == %Request{
             metadata: %Metadata{operation: :login, notify: [], send?: true},
             args: %{}
           }
  end
end
