use Mix.Config

config :potterhat_metrics,
  telemetry_subscribers: %{
    "statix-reporter" => PotterhatMetrics.StatixReporter
  }

# 8125 is DogStatsD's default port
config :statix,
  host: {:system, "POTTERHAT_STATSD_HOST", "127.0.0.1"},
  port: {:system, "POTTERHAT_STATSD_PORT", 8125, {String, :to_integer}}

import_config "#{Mix.env()}.exs"
