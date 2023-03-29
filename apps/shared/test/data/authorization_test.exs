defmodule Shared.Data.AuthorizationTest do
  @moduledoc false

  use ExUnit.Case

  alias Shared.Data.Authorization

  test "new/1 returns an Authorization" do
    assert Authorization.new(%{"cookie" => "a_cookie", "token" => "a_token"}) == %Authorization{
             cookie: "a_cookie",
             token: "a_token"
           }

    assert Authorization.new(cookie: "a_cookie", token: "a_token") == %Authorization{
             cookie: "a_cookie",
             token: "a_token"
           }
  end
end
