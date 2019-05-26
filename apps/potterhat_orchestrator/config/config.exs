use Mix.Config

config :potterhat_orchestrator,
  nodes: {:apply, {Potterhat.Orchestrator.EnvConfigProvider, :get_configs, []}},
  active_nodes: []

import_config "#{Mix.env()}.exs"
