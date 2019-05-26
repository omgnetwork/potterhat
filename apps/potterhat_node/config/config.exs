use Mix.Config

config :potterhat_node,
  retry_period_ms: 5000,
  listen_events: [:new_head]

import_config "#{Mix.env()}.exs"
