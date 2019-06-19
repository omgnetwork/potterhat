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

defmodule PotterhatNodeTest do
  use ExUnit.Case
  import PotterhatNode.EthereumTestHelper
  alias PotterhatNode.Node
  alias PotterhatNode.Node.RPCResponse

  doctest PotterhatNode

  @node_config %PotterhatNode.NodeConfig{
    id: :test_node_start_link,
    label: "Test PotterhatNode.start_link/1 GenServer",
    client_type: :geth,
    rpc: "http://localhost",
    ws: "ws://localhost",
    priority: 1000
  }

  setup do
    {:ok, rpc_url, websocket_url} = start_mock_node()

    config =
      @node_config
      |> Map.put(:id, String.to_atom("#{@node_config.id}_#{:rand.uniform(999_999_999)}"))
      |> Map.put(:rpc, rpc_url)
      |> Map.put(:ws, websocket_url)

    {:ok,
     %{
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

  describe "get_label/1" do
    test "returns the node's label", meta do
      {:ok, pid} = Node.start_link(meta.config)
      assert Node.get_label(pid) == meta.config.label
    end
  end

  describe "get_priority/1" do
    test "returns the node's priority", meta do
      {:ok, pid} = Node.start_link(meta.config)
      assert Node.get_priority(pid) == meta.config.priority
    end
  end

  describe "rpc_request/3" do
    test "returns a Response struct", meta do
      {:ok, pid} = Node.start_link(meta.config)

      body = %{}
      headers = %{}

      {res, response} = Node.rpc_request(pid, body, headers)

      refute res == :ok
      refute %RPCResponse{} = response
    end
  end
end
