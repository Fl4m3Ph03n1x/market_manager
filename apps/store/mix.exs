defmodule Store.MixProject do
  use Mix.Project

  def project do
    [
      app: :store,
      version: "3.1.1",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.16",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: preferred_cli_env(),
      aliases: aliases()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:jason, "~> 1.2"},
      {:shared, in_umbrella: true},

      # Test and Dev
      {:mix_test_watch, "~> 1.0", only: [:dev, :test], runtime: false}
    ]
  end

  defp preferred_cli_env,
    do: [
      "test.unit": :test,
      "test.integration": :test,
      "test.watch": :test,
      coveralls: :test,
      "coveralls.detail": :test,
      "coveralls.post": :test,
      "coveralls.html": :test,
      "coveralls.github": :test
    ]

  defp aliases,
    do: [
      "test.unit": ["test test/unit"],
      "test.integration": ["test test/integration"]
    ]
end
