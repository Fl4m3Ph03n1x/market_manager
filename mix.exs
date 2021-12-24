defmodule MarketManager.MixProject do
  use Mix.Project

  def project, do:
    [
      apps_path: "apps",
      version: "0.1.0",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      releases: releases()
    ]

  # Dependencies listed here are available only for this
  # project and cannot be accessed from applications inside
  # the apps folder.
  #
  # Run "mix help deps" for examples and options.
  defp deps, do:
    [
      {:bakeware, "~> 0.2.2"}
    ]


  defp releases, do:
    [
      desktop: [
        steps: [:assemble, &Bakeware.assemble/1],
        applications: [
          web_interface: :permanent,
          runtime_tools: :permanent
        ],
        include_executables_for: [:windows]
      ]
    ]

end
