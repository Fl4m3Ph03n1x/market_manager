defmodule Manager.MixProject do
  use Mix.Project

  def project do
    [
      app: :manager,
      version: "4.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.14",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: preferred_cli_env(),
      aliases: aliases()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps,
    do: [
      {:store, in_umbrella: true},
      {:auction_house, in_umbrella: true},
      {:shared, in_umbrella: true},

      # Testing and Dev
      {:mix_test_watch, "~> 1.0", only: [:dev, :test], runtime: false},
      {:mock, "~> 0.3.0", only: [:dev, :test]},
      {:gradient, github: "esl/gradient", only: [:dev, :test], runtime: false}
    ]

  defp elixirc_paths(:test), do: ["test/support", "lib"]
  defp elixirc_paths(_), do: ["lib"]

  defp preferred_cli_env,
    do: [
      "test.unit": :test,
      "test.integration": :test,
      "test.watch": :test
    ]

  defp aliases,
    do: [
      "test.unit": ["test test/unit"],
      "test.integration": ["test test/integration"]
    ]
end
