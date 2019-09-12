use Mix.Config

config :potterhat_node,
  nodes: {:apply, {PotterhatNode.EnvConfigProvider, :get_configs, []}},
  retry_interval_ms: {:system, "POTTERHAT_NODE_RETRY_INTERVAL", 5000, {String, :to_integer}},
  telemetry_subscribers: %{
    "node-event-logger" => PotterhatNode.EventLogger
  }

import_config "#{Mix.env()}.exs"
