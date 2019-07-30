Path.join(["rel", "plugins", "*.exs"])
|> Path.wildcard()
|> Enum.map(&Code.eval_file(&1))

use Distillery.Releases.Config,
  default_release: :potterhat,
  default_environment: Mix.env()

environment :dev do
  set dev_mode: true
  set include_erts: false
  set cookie: :dev
end

environment :prod do
  set include_erts: true
  set include_src: false
  set cookie: :prod
end

release :potterhat do
  set version: current_version(:potterhat_node)
  set vm_args: "rel/vm.args"
  set applications: [
    :runtime_tools,
    potterhat_metrics: :permanent,
    potterhat_node: :permanent,
    potterhat_rpc: :permanent,
    potterhat_utils: :permanent
  ]

  set commands: []
end
