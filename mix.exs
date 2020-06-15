defmodule MarketManager.MixProject do
  use Mix.Project

  @test_envs [:unit, :integration]

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
      elixirc_paths: elixirc_paths(Mix.env),
      escript: escript(),
      test_paths: test_paths(Mix.env)
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: applications(Mix.env),
      mod: {MarketManager.Application, [env: Mix.env]}
    ]
  end

  ###########
  # Private #
  ###########

  defp applications(:integration), do: applications(:default) ++ [:cowboy, :plug]
  defp applications(_),     do: [:logger]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:httpoison, "~> 1.6"},
      {:jason, "~> 1.2"},

      # Testing and Dev
      {:hammox, "~> 0.2", only: @test_envs},
      {:mix_test_watch, "~> 1.0", only: @test_envs, runtime: false},
      {:plug_cowboy, "~> 2.0", only: @test_envs}
    ]
  end

  defp elixirc_paths(env) when env in @test_envs, do: ["test/support", "lib"]
  defp elixirc_paths(_),     do: ["lib"]

  defp escript() do
    [
      main_module: MarketManager.CLI,
      comment: "Makes requests to warframe market."
    ]
  end

  defp test_paths(:integration), do: ["test/integration"]
  defp test_paths(:unit), do: ["test/unit"]
  defp test_paths(_), do: ["test/unit"]

end
