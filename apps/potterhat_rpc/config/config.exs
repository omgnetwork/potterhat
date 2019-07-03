use Mix.Config

config :potterhat_rpc,
  rpc_port: {:system, "RPC_PORT", 8545, {String, :to_integer}},
  telemetry_subscribers: %{
    "rpc-event-logger" => PotterhatRPC.EventLogger
  }

import_config "#{Mix.env()}.exs"
