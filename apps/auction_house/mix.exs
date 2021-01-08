defmodule AuctionHouse.MixProject do
  use Mix.Project

  def project, do:
    [
      app: :auction_house,
      version: "1.0.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.11",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      test_coverage: [tool: ExCoveralls]
    ]

  def application, do:
    [
      extra_applications: [:logger, :runtime_tools]
    ]

  defp deps, do:
    [
      {:rop, "~> 0.5"},
      {:httpoison, "~> 1.6"},
      {:jason, "~> 1.2"},
      {:recase, "~> 0.5"},
      {:jobs, git: "https://github.com/uwiger/jobs.git", tag: "0.9.0"},

      # Test and Dev
      {:mix_test_watch, "~> 1.0", only: :dev, runtime: false},
      {:plug_cowboy, "~> 2.0", only: [:dev, :test]},
      {:bypass, "~> 2.1", only: [:dev, :test]}
    ]

    defp elixirc_paths(:test), do: ["test/support", "lib"]
    defp elixirc_paths(_), do: ["lib"]
end
