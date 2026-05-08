defmodule Ari.MixProject do
  use Mix.Project

  def project do
    [
      app: :ari,
      version: "0.1.0",
      elixir: "~> 1.14",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {Ari.Application, []},
      extra_applications: [:logger, :runtime_tools, :os_mon]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:phoenix, "~> 1.7.14"},
      {:phoenix_ecto, "~> 4.6.2"},
      {:ecto_sql, "~> 3.12.0"},
      {:postgrex, ">= 0.0.0"},
      {:phoenix_html, "~> 4.1.1"},
      {:phoenix_live_reload, "~> 1.5.3", only: :dev},
      # TODO bump on release to {:phoenix_live_view, "~> 1.0.0"},
      {:phoenix_live_view, "~> 1.0.0-rc.6", override: true},
      {:floki, ">= 0.30.0", only: :test},
      {:phoenix_live_dashboard, "~> 0.8.4"},
      {:esbuild, "~> 0.8.1", runtime: Mix.env() == :dev},
      {:tailwind, "~> 0.2.3", runtime: Mix.env() == :dev},
      {:heroicons,
       github: "tailwindlabs/heroicons",
       tag: "v2.1.5",
       sparse: "optimized",
       app: false,
       compile: false,
       depth: 1},
      {:swoosh, "~> 1.17.1"},
      {:finch, "~> 0.19"},
      {:telemetry_metrics, "~> 1.0"},
      {:telemetry_poller, "~> 1.1"},
      {:ecto_psql_extras, "~> 0.7"},
      {:gettext, "~> 0.26"},
      {:jason, "~> 1.4.4"},
      {:dns_cluster, "~> 0.1.3"},
      {:bandit, "~> 1.5.7"},
      {:sweet_xml, "~> 0.7.4"},
      {:xml_builder, "~> 2.3"},
      {:uuid, "~> 1.1.8" },
      {:bcrypt_elixir, "~> 3.1"},
      {:joken, "~> 2.6.2"}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to install project dependencies and perform other setup tasks, run:
  #
  #     $ mix setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      setup: ["deps.get", "ecto.setup", "assets.setup", "assets.build"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"],
      "assets.setup": ["tailwind.install --if-missing", "esbuild.install --if-missing"],
      "assets.build": ["tailwind ari", "esbuild ari"],
      "assets.deploy": [
        "tailwind ari --minify",
        "esbuild ari --minify",
        "phx.digest"
      ]
    ]
  end
end
