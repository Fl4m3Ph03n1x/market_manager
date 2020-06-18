defmodule MarketManager.MixProject do
  use Mix.Project

  @test_envs [:test, :integration]

  ##########
  # Public #
  ##########

  def project do
    [
      app: :market_manager,
      version: "0.1.0",
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      elixirc_paths: elixirc_paths(Mix.env()),
      escript: escript(),
      test_paths: test_paths(Mix.env()),
      aliases: aliases()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {MarketManager.Application, [env: Mix.env()]}
    ]
  end

  ###########
  # Private #
  ###########

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:httpoison, "~> 1.6"},
      {:jason, "~> 1.2"},

      # Testing and Dev
      {:hammox, "~> 0.2", only: @test_envs},
      {:plug_cowboy, "~> 2.0", only: @test_envs},
      {:mix_test_watch, "~> 1.0", only: @test_envs, runtime: false},
      {:credo, "~> 1.4", only: [:dev] ++ @test_envs, runtime: false}
    ]
  end

  defp elixirc_paths(env) when env in @test_envs, do: ["test/support", "lib"]
  defp elixirc_paths(_), do: ["lib"]

  defp escript() do
    [
      main_module: MarketManager.CLI,
      comment: "Makes requests to warframe market."
    ]
  end

  defp test_paths(:integration), do: ["test/integration"]
  defp test_paths(_), do: ["test/unit"]

  defp aliases do
    [
      "test.all": ["test.unit", "test.integration"],
      "test.unit": &run_unit_tests/1,
      "test.integration": &run_integration_tests/1
    ]
  end

  def run_integration_tests(args), do: test_with_env("integration", args)
  def run_unit_tests(args), do: test_with_env("test", args)

  def test_with_env(env, args) do
    args = if IO.ANSI.enabled?(), do: ["--color" | args], else: ["--no-color" | args]
    IO.puts("==> Running tests with `MIX_ENV=#{env}`")

    {_, res} =
      System.cmd("mix", ["test" | args],
        into: IO.binstream(:stdio, :line),
        env: [{"MIX_ENV", to_string(env)}]
      )

    if res > 0 do
      System.at_exit(fn _ -> exit({:shutdown, 1}) end)
    end
  end
end
