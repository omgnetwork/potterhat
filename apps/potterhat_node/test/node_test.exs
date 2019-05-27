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

defmodule Potterhat.NodeTest do
  use ExUnit.Case
  alias Potterhat.Node
  alias Potterhat.Node.MockEthereumNode

  doctest Potterhat.Node

  @node_config %Potterhat.Node.NodeConfig{
    id: :test_node_start_link,
    label: "Test Node.start_link/1 GenServer",
    client: :geth,
    rpc: "http://localhost",
    ws: "ws://localhost",
    priority: 1000
  }

  setup do
    # Starts an Ethereum client
    {:ok, {server_ref, rpc_url, websocket_url}} = MockEthereumNode.start(self())
    on_exit(fn -> MockEthereumNode.shutdown(server_ref) end)

    config =
      @node_config
      |> Map.put(:id, String.to_atom("#{@node_config.id}_#{:rand.uniform(999999999)}"))
      |> Map.put(:rpc, rpc_url)
      |> Map.put(:ws, websocket_url)

    {:ok, %{
      config: config
    }}
  end

  describe "start_link/1" do
    test "returns a pid", meta do
      {res, pid} = Node.start_link(meta.config)

      assert res == :ok
      assert is_pid(pid)

      # This stops the node before the mock websocket server goes down.
      :ok = GenServer.stop(pid)
    end

    test "starts a GenServer with the given config", meta do
      {:ok, pid} = Node.start_link(meta.config)

      assert GenServer.call(pid, :get_label) == meta.config.label
      assert GenServer.call(pid, :get_priority) == meta.config.priority

      # This stops the node before the mock websocket server goes down.
      :ok = GenServer.stop(pid)
    end
  end

  describe "stop/1" do
    test "stops the node when given a node's pid", meta do
      {:ok, pid} = Node.start_link(meta.config)

      res = Node.stop(pid)

      assert res == :ok
      refute Process.alive?(pid)
    end
  end
end
