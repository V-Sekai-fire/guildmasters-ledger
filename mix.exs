defmodule GuildmastersLedger.MixProject do
  use Mix.Project

  def project do
    [
      app: :guildmasters_ledger,
      version: "0.1.0",
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      test_coverage: [tool: ExCoveralls],
      dialyzer: dialyzer(),
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.html": :test,
        "coveralls.json": :test,
        dialyzer: :dev
      ],
      aliases: aliases()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {GuildmastersLedger.Application, []}
    ]
  end

  defp deps do
    [
      # Local subrepo dependency
      {:aria_hybrid_planner, path: "subrepos/aria-hybrid-planner", only: [:dev, :test]},

      # Database dependencies for bitemporal 6NF support
      {:ecto_sql, "~> 3.10"},
      {:postgrex, ">= 0.0.0"},

      # Godot integration (when available)
      # {:membrane_unifex, "~> 0.1"},

      # Networking for real-time updates
      {:plug_cowboy, "~> 2.6"},

      # Test dependencies
      {:mox, "~> 1.0", only: :test},
      {:excoveralls, "~> 0.18", only: :test},
      {:ex_doc, "~> 0.31", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false}
    ]
  end

  defp aliases do
    [
      setup: ["deps.get"],
      test: ["test"]
    ]
  end

  defp dialyzer do
    [
      plt_add_deps: :apps_direct,
      plt_add_apps: [:mix, :ex_unit],
      ignore_warnings: ".dialyzer_ignore.exs",
      flags: [:error_handling, :underspecs, :unknown]
    ]
  end
end
