defmodule WebInterface.Persistence.ButtonTest do
  @moduledoc false

  use ExUnit.Case, async: true

  alias WebInterface.Persistence.Button, as: ButtonStore

  describe "set_button/2" do
    test "sets button correctly" do
      deps = %{
        name: :data,
        recover: fn :data -> {:ok, :table} end,
        put: fn :table, :button, :activate -> {:ok, nil} end
      }

      :ok = ButtonStore.set_button(:activate, deps)
    end

    test "returns error if setting button fails" do
      deps = %{
        name: :data,
        recover: fn :data -> {:ok, :table} end,
        put: fn :table, :button, :activate -> {:error, :some_error} end
      }

      {:error, :some_error} = ButtonStore.set_button(:activate, deps)
    end
  end

  describe "get_button/1" do
    test "gets button correctly" do
      deps = %{
        name: :data,
        recover: fn :data -> {:ok, :table} end,
        get: fn :table, :button, nil -> {:ok, :activate} end
      }

      assert {:ok, :activate} == ButtonStore.get_button(deps)
    end

    test "returns error if getting button fails" do
      deps = %{
        name: :data,
        recover: fn :data -> {:ok, :table} end,
        get: fn :table, :button, nil -> {:error, :some_error} end
      }

      assert {:error, :some_error} == ButtonStore.get_button(deps)
    end
  end

  describe "button_selected?/2" do
    test "returns true if button is selected" do
      deps = %{
        name: :data,
        recover: fn :data -> {:ok, :table} end,
        get: fn :table, :button, nil -> {:ok, :activate} end
      }

      assert ButtonStore.button_selected?(:activate, deps)
    end

    test "returns false if button is not selected" do
      deps = %{
        name: :data,
        recover: fn :data -> {:ok, :table} end,
        get: fn :table, :button, nil -> {:ok, :activate} end
      }

      refute ButtonStore.button_selected?(:deactivate, deps)
    end

    test "returns false if error occurs" do
      deps = %{
        name: :data,
        recover: fn :data -> {:ok, :table} end,
        get: fn :table, :button, nil -> {:error, :some_error} end
      }

      refute ButtonStore.button_selected?(:deactivate, deps)
    end

    test "returns false if no button is selected" do
      deps = %{
        name: :data,
        recover: fn :data -> {:ok, :table} end,
        get: fn :table, :button, nil -> {:ok, nil} end
      }

      refute ButtonStore.button_selected?(:deactivate, deps)
    end
  end
end
