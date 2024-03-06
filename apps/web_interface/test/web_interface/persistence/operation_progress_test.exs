defmodule WebInterface.Persistence.OperationProgressTest do
  @moduledoc false

  use ExUnit.Case, async: true

  alias WebInterface.Persistence.OperationProgress, as: OperationProgressStore

  describe "in_progress?/1" do
    test "returns false by default" do
      deps = %{
        name: :data,
        recover: fn :data -> {:ok, :table} end,
        get: fn :table, :operation_in_progress, default -> {:ok, default} end
      }

      refute OperationProgressStore.in_progress?(deps)
    end

    test "returns if an operation is in progress" do
      deps = %{
        name: :data,
        recover: fn :data -> {:ok, :table} end,
        get: fn :table, :operation_in_progress, _default -> {:ok, true} end
      }

      assert OperationProgressStore.in_progress?(deps)
    end

    test "returns error if getting fails" do
      deps = %{
        name: :data,
        recover: fn :data -> {:ok, :table} end,
        get: fn :table, :operation_in_progress, _default -> {:error, :some_error} end
      }

      assert {:error, :some_error} == OperationProgressStore.in_progress?(deps)
    end
  end

  describe "set_progress/2" do
    test "sets progress correctly" do
      deps = %{
        name: :data,
        recover: fn :data -> {:ok, :table} end,
        put: fn :table, :operation_in_progress, true -> {:ok, :updated_table} end
      }

      assert :ok == OperationProgressStore.set_progress(true, deps)
    end

    test "returns error if setting progress fails" do
      deps = %{
        name: :data,
        recover: fn :data -> {:ok, :table} end,
        put: fn :table, :operation_in_progress, true -> {:error, :some_error} end
      }

      assert {:error, :some_error} == OperationProgressStore.set_progress(true, deps)
    end
  end
end
