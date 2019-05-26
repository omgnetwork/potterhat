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

defmodule PotterhatPubSub.Application do
  @moduledoc false
  use Application

  @port 8546

  def start(_type, _args) do
    children = [
      {Plug.Cowboy, scheme: :http, plug: PotterhatPubSub.Endpoint, options: [port: @port, dispatch: dispatch()]},
      Registry.child_spec(keys: :duplicate, name: Registry.PotterhatPubSub)
    ]

    opts = [strategy: :one_for_one, name: PotterhatPubSub.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp dispatch do
    [
      {:_, [
        {:_, PotterhatPubSub.WebsocketHandler, []}
      ]}
    ]
  end
end
