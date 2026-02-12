defmodule WebInterface.Persistence.UserTest do
  @moduledoc false

  use ExUnit.Case

  alias ETS
  alias Shared.Data.User
  alias WebInterface.Persistence.User, as: UserStore

  describe "has_user?" do
    test "returns false if there is no user set" do
      refute UserStore.has_user?()
    end

    test "returns true if there is a user set" do
      UserStore.set_user(User.new(ingame_name: "Username", slug: "username", patreon?: false))

      assert UserStore.has_user?()

      UserStore.set_user(nil)
    end
  end

  describe "get_user" do
    test "returns nil if there is no user set" do
      {:ok, user} = UserStore.get_user()
      assert is_nil(user)
    end

    test "returns the set user" do
      user = User.new(ingame_name: "Username", slug: "username", patreon?: false)
      :ok = UserStore.set_user(user)

      {:ok, fetched_user} = UserStore.get_user()
      assert fetched_user == user

      UserStore.set_user(nil)
    end
  end

  describe "set_user" do
    test "sets the user correctly" do
      user = User.new(ingame_name: "Username", slug: "slug", patreon?: false)
      :ok = UserStore.set_user(user)

      {:ok, fetched_user} = UserStore.get_user()
      assert fetched_user == user

      UserStore.set_user(nil)
    end
  end
end
