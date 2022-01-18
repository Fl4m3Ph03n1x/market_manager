defmodule AuctionHouse.MixProject do
  use Mix.Project

  def project do
    [
      app: :auction_house,
      version: "1.0.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.13",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      test_coverage: [tool: ExCoveralls]
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
      {:rop, "~> 0.5"},
      {:httpoison, "~> 1.8"},
      {:jason, "~> 1.2"},
      {:recase, "~> 0.7"},
      {:jobs, "~> 0.10.0"},

      # Test and Dev
      {:mix_test_watch, "~> 1.0", only: :dev, runtime: false},
      {:plug_cowboy, "~> 2.5", only: [:dev, :test]},
      {:bypass, "~> 2.1", only: [:dev, :test]}
    ]
  end

  defp elixirc_paths(:test), do: ["test/support", "lib"]
  defp elixirc_paths(_), do: ["lib"]
end
