use Mix.Config

config :potterhat_orchestrator,
  nodes: {:apply, {PotterhatOrchestrator.EnvConfigProvider, :get_configs, []}},
  active_nodes: []

import_config "#{Mix.env()}.exs"
