defmodule AuctionHouse.Impl.UseCase.Data.MetadataTest do
  @moduledoc false

  use ExUnit.Case, async: true

  alias AuctionHouse.Impl.UseCase.Data.Metadata

  test "returns a new struct" do
    pid = self()

    assert Metadata.new(:login, [pid]) == %Metadata{
             operation: :login,
             notify: [pid],
             send?: false
           }

    assert Metadata.new(:login, [pid], true) == %Metadata{
             operation: :login,
             notify: [pid],
             send?: true
           }
  end

  test "marks send to true when it is marked to send" do
    pid = self()
    meta = Metadata.new(:login, [pid])

    assert Metadata.mark_to_send(meta) ==
             %Metadata{
               operation: :login,
               notify: [pid],
               send?: true
             }
  end
end
