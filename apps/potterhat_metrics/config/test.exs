use Mix.Config

# Extending the assert_receive_timeout as PotterhatMetrics.StatixReporterTest
# needs to monitor packets from Statix library.
config :ex_unit,
  assert_receive_timeout: 500
