defmodule PotterhatNode.MixProject do
  use Mix.Project

  def project do
    [
      app: :potterhat_node,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.8",
      elixirc_paths: elixirc_paths(Mix.env),
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {PotterhatNode.Application, []}
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_),     do: ["lib"]

  defp deps do
    [
      {:deferred_config, "~> 0.1.0"},
      {:ethereumex, "~> 0.5.3"},
      {:jason, "~> 1.1"},
      {:websockex, "~> 0.4.0"},
      {:httpoison, "~> 1.4"},
      {:logger_file_backend, "~> 0.0.10"},
      # Used for mocking websocket servers
      {:plug_cowboy, "~> 2.0", only: :test}
    ]
  end
end
