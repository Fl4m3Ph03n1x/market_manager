defmodule MarketManager.MixProject do
  use Mix.Project

  alias Bakeware
  alias ExCoveralls

  def project,
    do: [
      apps_path: "apps",
      version: "2.1.7",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: preferred_cli_env(),
      releases: releases(),
      aliases: aliases(),

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
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false},
      {:excoveralls, "~> 0.18", only: :test},
      {:dialyxir, "~> 1.0", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.27", only: :dev, runtime: false}
    ]

  defp preferred_cli_env,
    do: [
      coveralls: :test,
      "coveralls.detail": :test,
      "coveralls.post": :test,
      "coveralls.html": :test
    ]

  defp aliases do
    child_tests =
      Path.wildcard("apps/*")
      |> Enum.map(&String.replace(&1, "apps/", ""))
      |> Enum.map(fn app -> "cmd --app #{app} mix test --color" end)

    [test: child_tests]
  end

  defp releases,
    do: [
      market_manager: [
        applications: [
          web_interface: :permanent,
          runtime_tools: :permanent
        ],
        steps: [:assemble, :tar, &rename_tar/1],
        include_executables_for: [:windows]
      ]
    ]

  defp rename_tar(release) do
    tar_folder_path =
      release.path
      |> Path.join("../../")
      |> Path.expand()

    tar_path = Path.join(tar_folder_path, "#{release.name}-#{release.version}.tar.gz")
    new_tar_path = Path.join(tar_folder_path, "application-data.tar.gz")

    case File.rename(tar_path, new_tar_path) do
      :ok -> release
      err -> err
    end
  end
end
