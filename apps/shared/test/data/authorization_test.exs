defmodule Shared.Data.AuthorizationTest do
  @moduledoc false

  use ExUnit.Case, async: true

  alias Shared.Data.Authorization

  describe "new/1" do
    test "returns an Authorization" do
      assert Authorization.new(%{"access_token" => "a_token"}) == %Authorization{
               access_token: "a_token"
             }
    end

    test "raises if access_token is empty" do
      assert_raise FunctionClauseError, fn -> Authorization.new(%{"access_token" => ""}) end
    end
  end

  test "inspect/1 hides the access_token" do
    assert inspect(%Authorization{access_token: "a_token"}) == "#Shared.Data.Authorization<...>"
  end
end
