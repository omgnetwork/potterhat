use Mix.Config

config :potterhat_node,
  nodes: {:apply, {PotterhatNode.EnvConfigProvider, :get_configs, []}},
  active_nodes: [],
  retry_period_ms: 5000,
  telemetry_subscribers: %{
    "node-event-logger" => PotterhatNode.EventLogger
  }

import_config "#{Mix.env()}.exs"
