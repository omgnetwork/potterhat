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

defmodule PotterhatNode.Subscription.Log do
  @moduledoc """
  Listens for log events.
  """
  use WebSockex

  @subscription_id 3

  #
  # Client API
  #

  @doc """
  Starts a GenServer that listens to log events.
  """
  @spec start_link(String.t(), Keyword.t()) :: {:ok, pid()} | no_return()
  def start_link(url, opts) do
    name = String.to_atom("listener_logs_#{opts[:node_id]}")
    opts = Keyword.put(opts, :name, name)

    {:ok, pid} = WebSockex.start_link(url, __MODULE__, opts, opts)
    :ok = listen(pid)

    {:ok, pid}
  end

  defp listen(pid) do
    payload = %{
      jsonrpc: "2.0",
      id: @subscription_id,
      method: "eth_subscribe",
      params: [
        "logs",
        %{}
      ]
    }

    WebSockex.send_frame(pid, {:text, Jason.encode!(payload)})
  end

  #
  # Server API
  #

  @doc false
  @spec init(Keyword.t()) :: {:ok, map()}
  def init(opts) do
    state = %{
      label: opts[:label],
      listener: opts[:listener]
    }

    {:ok, state}
  end

  @doc false
  @impl true
  def handle_frame({_type, msg}, state) do
    {:ok, decoded} = Jason.decode(msg)
    _ = GenServer.cast(state[:listener], {:event_received, :logs, decoded})
    {:ok, state}
  end
end
