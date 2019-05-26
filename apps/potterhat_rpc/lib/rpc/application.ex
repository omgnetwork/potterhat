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
  require Logger

  @port 8545

  def start(_type, _args) do
    port =
      case System.get_env("RPC_PORT") do
        nil -> @port
        "" -> @port
        port -> String.to_integer(port)
      end

    Logger.info("Starting RPC server on port #{port}")

    children = [
      {Plug.Cowboy, scheme: :http, plug: PotterhatRPC.Router, options: [port: port]},
    ]

    opts = [strategy: :one_for_one, name: PotterhatRPC.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
