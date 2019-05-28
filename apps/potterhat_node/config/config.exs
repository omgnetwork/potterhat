use Mix.Config

config :potterhat_node,
  retry_period_ms: 5000,
  listen_events: [:new_head],
  default_subscribers: [Potterhat.Node.EventLogger]

import_config "#{Mix.env()}.exs"
