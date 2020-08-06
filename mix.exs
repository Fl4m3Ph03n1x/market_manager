defmodule MarketManager.MixProject do
  use Mix.Project

  def project do
    [
      apps_path: "apps",
      version: "1.0.0",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: preferred_cli_env()
    ]
  end

  defp deps do
    [
      {:credo, "~> 1.4", only: [:test, :dev], runtime: false},
      {:excoveralls, "~> 0.10", only: :test},
      {:mix_test_watch, "~> 1.0", only: :dev, runtime: false}
    ]
  end

  defp preferred_cli_env do
    [
      coveralls: :test,
      "coveralls.detail": :test,
      "coveralls.post": :test,
      "coveralls.html": :test
    ]
  end

end
