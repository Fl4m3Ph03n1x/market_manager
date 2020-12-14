defmodule Cli.ParserTest do
  use ExUnit.Case

  alias Cli.{Error, Parser, Request}

  describe "parse" do
    test "returns parsed map of user input" do
      params = [
        "--action=activate",
        "--syndicates=red_veil",
        "--strategy=equal_to_lowest"
      ]

      actual = Parser.parse(params)
      expected = {:ok, %Request{
        action: "activate",
        strategy: "equal_to_lowest",
        syndicates: ["red_veil"]}
      }

      assert actual == expected
    end

    test "returns error if an unspecified option is given" do
      params = [
        "--bad_option=1",
        "--strategy=equal_to_lowest"
      ]

      actual = Parser.parse(params)
      expected = {:error, [%Error{input: "--bad_option", type: :bad_option}]}

      assert actual == expected
    end
  end
end
