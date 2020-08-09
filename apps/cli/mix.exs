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
      escript: escript(),
      elixirc_paths: elixirc_paths(Mix.env)
    ]

  def application, do:
    [
      extra_applications: [:logger]
    ]

  defp deps, do: [
    {:manager, in_umbrella: true},
    {:hammox, "~> 0.2"}
  ]

  defp escript, do:
    [
      main_module: Cli,
      comment: "Makes requests to warframe market."
    ]

  defp elixirc_paths(:test), do: ["test/support", "lib"]
  defp elixirc_paths(_),     do: ["lib"]

end
