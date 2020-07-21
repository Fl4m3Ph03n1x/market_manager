defmodule MarketManager.MixProject do
  use Mix.Project

  ##########
  # Public #
  ##########

  def project do
    [
      app: :market_manager,
      version: "0.1.0",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      elixirc_paths: elixirc_paths(Mix.env()),
      escript: escript(),
      test_paths: test_paths(),
      aliases: aliases(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: preferred_cli_env(),

      # Docs
      name: "Market Manager",
      source_url: "https://github.com/Fl4m3Ph03n1x/market_manager",
      homepage_url: "http://market_manager",
      docs: [main: "MarketManager", # The main page in the docs
            logo: "logo.png",
            extras: ["README.md"]]
      ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {MarketManager.Application, [env: Mix.env()]}
    ]
  end

  ###########
  # Private #
  ###########

  defp deps do
    [
      {:httpoison, "~> 1.6"},
      {:jason, "~> 1.2"},
      {:rop, "~> 0.5"},

      # Testing and Dev
      {:hammox, "~> 0.2", only: :test},
      {:plug_cowboy, "~> 2.0", only: :test},
      {:mix_test_watch, "~> 1.0", only: [:dev, :test], runtime: false},
      {:credo, "~> 1.4", only: [:test, :dev], runtime: false},
      {:excoveralls, "~> 0.12", only: :test},
      {:dialyxir, "~> 1.0", only: [:dev], runtime: false},
      {:ex_doc, "~> 0.22", only: :dev, runtime: false},
      {:inch_ex, only: :docs}
    ]
  end

  defp elixirc_paths(:test), do: ["test/support", "lib"]
  defp elixirc_paths(_), do: ["lib"]

  defp escript do
    [
      main_module: MarketManager.CLI,
      comment: "Makes requests to warframe market."
    ]
  end

  defp test_paths, do: ["test/unit", "test/integration"]

  defp aliases do
    [
      "test.watch.unit": ["test.watch test/unit/"],
      "test.watch.integration": ["test.watch test/integration/"],
      "test.unit": ["test test/unit/"],
      "test.integration": ["test test/integration/"]
    ]
  end

  defp preferred_cli_env do
    [
      "test.watch.unit": :test,
      "test.watch.integration": :test,
      "test.integration": :test,
      "test.unit": :test,
      coveralls: :test,
      "coveralls.detail": :test,
      "coveralls.post": :test,
      "coveralls.html": :test
    ]
  end
end
