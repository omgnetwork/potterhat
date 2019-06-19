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

defmodule PotterhatNode.MockEthereumNode do
  @moduledoc """
  A mock of an Ethereum node for testing purposes.
  """
  # This module is heavily inspired by WebSockex.TestServer.
  # See https://github.com/Azolo/websockex/blob/master/test/support/test_server.ex
  alias __MODULE__.{RPC, WebSocket}
  alias Plug.Cowboy
  alias Plug.Cowboy.Handler

  def start(pid) when is_pid(pid) do
    ref = make_ref()
    port = get_port()
    {:ok, agent_pid} = Agent.start_link(fn -> :ok end)
    rpc_url = "http://localhost:#{port}"
    ws_url = "ws://localhost:#{port}/ws"

    opts = [dispatch: dispatch({pid, agent_pid}), port: port, ref: ref]

    case Cowboy.http(__MODULE__, [], opts) do
      {:ok, _} ->
        {:ok, {ref, rpc_url, ws_url}}

      {:error, :eaddrinuse} ->
        start(pid)
    end
  end

  def ws_emit(pid, data) do
    send(pid, {:send, data})
  end

  def shutdown(ref) do
    Cowboy.shutdown(ref)
  end

  def receive_socket_pid do
    receive do
      pid when is_pid(pid) -> pid
    after
      10_000 -> raise "No Server Socket pid"
    end
  end

  defp dispatch(tuple) do
    [
      {:_,
       [
         {"/ws", WebSocket, [tuple]},
         {:_, Handler, {RPC, []}}
       ]}
    ]
  end

  defp get_port do
    unless Process.whereis(__MODULE__), do: start_ports_agent()

    Agent.get_and_update(__MODULE__, fn port -> {port, port + 1} end)
  end

  defp start_ports_agent do
    Agent.start(fn -> Enum.random(50_000..63_000) end, name: __MODULE__)
  end
end
