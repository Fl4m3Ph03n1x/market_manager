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
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      escript: escript()
    ]

  def application, do:
    [
      extra_applications: [:logger]
    ]

  defp deps, do: [
    {:manager, in_umbrella: true}
  ]

  defp escript, do:
    [
      main_module: MarketManager.CLI,
      comment: "Makes requests to warframe market."
    ]

end
