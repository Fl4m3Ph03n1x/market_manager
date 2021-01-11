defmodule Cli.MixProject do
  use Mix.Project

  def project, do:
    [
      app: :cli,
      version: "1.0.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.11",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      escript: escript(),
      elixirc_paths: elixirc_paths(Mix.env),
      test_coverage: [tool: ExCoveralls]
    ]

  def application, do:
    [
      extra_applications: [:logger, :runtime_tools],
      mod: {Cli.Application, []}
    ]

  defp deps, do: [
    {:recase, "~> 0.5"},
    {:manager, in_umbrella: true},
    {:rop, "~> 0.5"},
    {:typed_struct, "~> 0.2.1"},

    {:mock, "~> 0.3.0", only: :test},
    {:mix_test_watch, "~> 1.0", only: :dev, runtime: false}
  ]

  defp escript, do:
    [
      main_module: Cli,
      comment: "Command Line Interface for the MarketManager app.",
      path: "../../market_manager"
    ]

  defp elixirc_paths(:test), do: ["test/support", "lib"]
  defp elixirc_paths(_),     do: ["lib"]

end
