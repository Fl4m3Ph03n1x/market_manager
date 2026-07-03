defmodule Manager.MixProject do
  use Mix.Project

  def project do
    [
      app: :manager,
      version: "5.0.5",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.20",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      test_coverage: [tool: ExCoveralls],
      aliases: aliases()
    ]
  end

  def cli,
    do: [
      preferred_envs: [
        "test.unit": :test,
        "test.integration": :test,
        "test.watch": :test,
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test,
        "coveralls.github": :test
      ]
    ]

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
      {:mock, "~> 0.3.0", only: [:dev, :test]}
    ]

  defp elixirc_paths(:test), do: ["test/support", "lib"]
  defp elixirc_paths(_), do: ["lib"]

  defp aliases,
    do: [
      "test.unit": ["test test/unit"],
      "test.integration": ["test test/integration"]
    ]
end
