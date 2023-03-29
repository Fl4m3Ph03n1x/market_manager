defmodule Shared.Data.CredentialsTest do
  @moduledoc false

  use ExUnit.Case

  alias Shared.Data.Credentials

  test "new/1 returns Credentials" do
    assert Credentials.new("an_email", "a_password") == %Credentials{
             email: "an_email",
             password: "a_password"
           }
  end
end
