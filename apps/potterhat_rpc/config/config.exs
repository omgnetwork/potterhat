use Mix.Config

config :potterhat_rpc,
  rpc_port: {:system, "RPC_PORT", 8545, {String, :to_integer}},

import_config "#{Mix.env()}.exs"
