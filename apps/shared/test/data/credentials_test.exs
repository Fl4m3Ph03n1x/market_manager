defmodule Shared.Data.CredentialsTest do
  @moduledoc false

  use ExUnit.Case, async: true

  alias Shared.Data.Credentials

  test "new/1 returns Credentials" do
    assert Credentials.new("an_email", "a_password") == %Credentials{
             email: "an_email",
             password: "a_password"
           }
  end

  test "inspect/1 hides the password" do
    assert inspect(Credentials.new("an_email", "a_password")) ==
             "#Shared.Data.Credentials<email: \"an_email\", ...>"
  end
end
