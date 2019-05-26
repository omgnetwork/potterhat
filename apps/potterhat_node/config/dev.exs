use Mix.Config

config :logger, backends: [
  :console,
  {LoggerFileBackend, :debug_log}
]

config :logger, :debug_log,
  path: "/var/log/potterhat.log",
  level: :debug
