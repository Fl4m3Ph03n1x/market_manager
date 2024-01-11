defmodule Shared.MixProject do
  use Mix.Project

  def project do
    [
      app: :shared,
      version: "1.0.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.16",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: preferred_cli_env()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:morphix, "~> 0.8.1"},
      {:typed_struct, "~> 0.3.0"},
      {:jason, "~> 1.4"},

      # Test and Dev
      {:mix_test_watch, "~> 1.0", only: :dev, runtime: false},
      {:gradient, github: "esl/gradient", only: [:dev, :test], runtime: false}
    ]
  end

  defp preferred_cli_env,
    do: [
      coveralls: :test,
      "coveralls.detail": :test,
      "coveralls.post": :test,
      "coveralls.html": :test,
      "coveralls.github": :test
    ]
end
