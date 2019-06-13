use Mix.Config

config :potterhat_node,
  nodes: {:apply, {PotterhatNode.EnvConfigProvider, :get_configs, []}},
  active_nodes: [],
  retry_period_ms: 5000,
  listen_events: [:new_head]

import_config "#{Mix.env()}.exs"
