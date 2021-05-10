defmodule Store.MixProject do
  use Mix.Project

  def project, do:
    [
      app: :store,
      version: "1.0.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      test_coverage: [tool: ExCoveralls]
    ]

  def application, do:
    [
      extra_applications: [:logger]
    ]

  defp deps, do:
    [
      {:jason, "~> 1.2"},
      {:rop, "~> 0.5"},

      {:mix_test_watch, "~> 1.0", only: :dev, runtime: false}
    ]

end
