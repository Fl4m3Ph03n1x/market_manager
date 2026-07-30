defmodule WebInterface.PersistenceTest do
  @moduledoc false

  use ExUnit.Case, async: true

  alias WebInterface.Persistence

  describe "init/4" do
    test "creates the table and stores the initial values" do
      strategies = [:strategy]
      syndicates = [:syndicate]
      user = :user
      test_pid = self()

      table = %{
        name: :test_data,
        new: fn [name: :test_data, protection: :public] -> {:ok, :table} end,
        put: fn :table, key, value ->
          send(test_pid, {key, value})
          {:ok, :table}
        end
      }

      assert Persistence.init(strategies, syndicates, user, table) == :ok
      assert_received {:syndicates, ^syndicates}
      assert_received {:strategies, ^strategies}
      assert_received {:user, ^user}
    end
  end
end