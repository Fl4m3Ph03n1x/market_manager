defmodule MarketManager.MixProject do
  use Mix.Project

  alias ExCoveralls

  def project,
    do: [
      apps_path: "apps",
      version: "2.2.9",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      test_coverage: [tool: ExCoveralls],
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

  def cli,
    do: [
      preferred_envs: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ]
    ]

  defp deps,
    do: [
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:excoveralls, "~> 0.18", only: :test},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.27", only: :dev, runtime: false},
      {:burrito, "~> 1.0"}
    ]

  defp releases,
    do: [
      market_manager: [
        applications: [
          web_interface: :permanent,
          runtime_tools: :permanent
        ],
        steps: [:assemble, &Burrito.wrap/1, &add_windows_icon/1],
        burrito: [
          targets: [
            windows: [os: :windows, cpu: :x86_64]
          ]
        ]
      ]
    ]

  defp add_windows_icon(%Mix.Release{} = release) do
    resource_hacker_path =
      Path.join([
        System.user_home!(),
        ".wine",
        "drive_c",
        "Program Files (x86)",
        "Resource Hacker",
        "ResourceHacker.exe"
      ])

    args = [
      resource_hacker_path,
      "-open",
      "burrito_out/market_manager_windows.exe",
      "-save",
      "burrito_out/market_manager_#{release.version}.exe",
      "-action",
      "addoverwrite",
      "-res",
      "apps/web_interface/priv/static/images/resized_logo_5_32x32.ico",
      "-mask",
      "ICONGROUP,1,1033"
    ]

    case System.cmd("wine", args, stderr_to_stdout: true) do
      {output, 0} ->
        Mix.shell().info(output)
        release

      {output, exit_code} ->
        Mix.raise("ResourceHacker failed with exit code #{exit_code}.\n\n#{output}")
    end
  end
end
