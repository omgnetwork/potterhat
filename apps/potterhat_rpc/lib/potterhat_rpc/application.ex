# Copyright 2019 OmiseGO Pte Ltd
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

defmodule PotterhatRPC.Application do
  @moduledoc false
  use Application
  alias PotterhatUtils.TelemetrySubscriber

  def start(_type, _args) do
    _ = DeferredConfig.populate(:potterhat_rpc)
    :ok = TelemetrySubscriber.attach_from_config(:potterhat_rpc)

    port = Application.get_env(:potterhat_rpc, :rpc_port)
    _ = :telemetry.execute([:rpc, :server, :starting], %{}, %{port: port})

    children = [
      {Plug.Cowboy, scheme: :http, plug: PotterhatRPC.Router, options: [port: port]}
    ]

    opts = [strategy: :one_for_one, name: PotterhatRPC.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
