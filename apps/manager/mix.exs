defmodule Manager.MixProject do
  use Mix.Project

  def project do
    [
      app: :manager,
      version: "2.0.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {Manager.Application, []}
    ]
  end

  defp deps do
    [
      {:rop, "~> 0.5"},
      {:store, in_umbrella: true},
      {:auction_house, in_umbrella: true}
    ]
  end
end
