use Mix.Config

config :potterhat_metrics,
  telemetry_subscribers: %{
    "statix-reporter" => PotterhatMetrics.StatixReporter
  }

# 8125 is DogStatsD's default port
config :statix,
  host: "127.0.0.1",
  port: 8125

import_config "#{Mix.env()}.exs"
