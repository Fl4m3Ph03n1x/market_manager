defmodule MarketManager.MixProject do
  use Mix.Project

  def project do
    [
      apps_path: "apps",
      version: "1.1.0",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: preferred_cli_env(),
      releases: releases(),

      # Docs
      name: "Market Manager",
      source_url: "https://github.com/Fl4m3Ph03n1x/market_manager",
      homepage_url: "https://fl4m3ph03n1x.github.io/market_manager/",
      docs: [
        main: "Manager", # The main page in the docs
        logo: "images/resized_logo.png",
        extras: ["README.md"],
        output: "docs"
      ]
    ]
  end

  defp deps, do:
    [
      {:credo, "~> 1.4", only: [:test, :dev], runtime: false},
      {:excoveralls, "~> 0.10", only: :test},
      {:mix_test_watch, "~> 1.0", only: :dev, runtime: false},
      {:dialyxir, "~> 1.0", only: [:dev], runtime: false},
      {:ex_doc, "~> 0.22", only: :dev, runtime: false}
    ]

  defp preferred_cli_env, do:
    [
      coveralls: :test,
      "coveralls.detail": :test,
      "coveralls.post": :test,
      "coveralls.html": :test
    ]

  defp releases, do:
    [
      market_manager: [
        applications: [
          cli: :permanent
        ]
      ]
    ]

end
