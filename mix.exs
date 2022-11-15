defmodule MarketManager.MixProject do
  use Mix.Project

  alias Bakeware
  alias ExCoveralls

  def project,
    do: [
      apps_path: "apps",
      version: "2.1.4",
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
        # The main page in the docs
        main: "Manager",
        logo: "images/resized_logo.png",
        extras: ["README.md"],
        output: "docs"
      ]
    ]

  defp deps,
    do: [
      {:bakeware, github: "bake-bake-bake/bakeware"},
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false},
      {:excoveralls, "~> 0.10", only: :test},
      {:dialyxir, "~> 1.0", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.22", only: :dev, runtime: false}
    ]

  defp preferred_cli_env,
    do: [
      coveralls: :test,
      "coveralls.detail": :test,
      "coveralls.post": :test,
      "coveralls.html": :test
    ]

  defp releases,
    do: [
      market_manager: [
        steps: [:assemble, &Bakeware.assemble/1],
        applications: [
          web_interface: :permanent,
          runtime_tools: :permanent
        ],
        include_executables_for: [:windows]
      ]
    ]
end
