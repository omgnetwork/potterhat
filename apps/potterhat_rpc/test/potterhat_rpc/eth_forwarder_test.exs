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

defmodule PotterhatRPC.EthForwarderTest do
  use PotterhatRPC.ConnCase, async: true
  import ExUnit.CaptureLog
  import PotterhatNode.EthereumTestHelper
  alias PotterhatNode.{ActiveNodes, Node}
  alias PotterhatRPC.EthForwarder

  #
  # Test setup
  #

  setup do
    {:ok, node_registry} = prepare_node_registry()

    {:ok, pid_1} = prepare_mock_node(node_registry: node_registry, priority: 10)
    {:ok, pid_2} = prepare_mock_node(node_registry: node_registry, priority: 20)

    # The nodes take some time to intialize, so we wait for 100ms.
    _ = Process.sleep(200)

    {:ok, %{
      nodes: [pid_1, pid_2],
      node_registry: node_registry
    }}
  end

  defp prepare_node_registry do
    name = String.to_atom("node_registry_#{:rand.uniform(999)}")
    ActiveNodes.start_link(name: name)
  end

  defp prepare_mock_node(opts) do
    node_registry = Keyword.get(opts, :node_registry, ActiveNodes)
    {:ok, rpc_url, websocket_url} = start_mock_node()

    config =
      %PotterhatNode.NodeConfig{
        id: String.to_atom("test_eth_forwarder_#{:rand.uniform(999_999_999)}"),
        label: "A mock node for EthForwarderTest",
        client_type: :geth,
        rpc: rpc_url,
        ws: websocket_url,
        priority: Keyword.get(opts, :priority, 100),
        node_registry: node_registry
      }

    Node.start_link(config)
  end

  #
  # Actual tests
  #

  describe "sanity check the mock ethereum node" do
    test "has two active nodes", meta do
      assert length(ActiveNodes.all(meta.node_registry)) == 2
    end
  end

  describe "forward/3" do
    test "returns a node's response", meta do
      header_params = %{"content-type" => "application/json"}

      body_params = %{
        "jsonrpc" => "2.0",
        "method" => "web3_clientVersion",
        "params" => [],
        "id" => :rand.uniform(999)
      }

      opts = [node_registry: meta.node_registry]
      {:ok, response} = EthForwarder.forward(body_params, header_params, opts)
      response = Jason.decode!(response.body)

      # The response should be from PotterhatNode.MockEthereumNode.RPC
      assert response["result"] == "PotterhatMockEthereumNode"
    end

    test "deregisters and falls back to the next active node when the first one fails", meta do
      assert length(ActiveNodes.all(meta.node_registry)) == 2
      header_params = %{"content-type" => "application/json"}

      body_params = %{
        "jsonrpc" => "2.0",
        "method" => "web3_clientVersion",
        "params" => [],
        "id" => :rand.uniform(999)
      }

      opts = [node_registry: meta.node_registry]
      true = Process.exit(List.first(meta.nodes), :normal)

      log = capture_log(fn ->
        {:ok, response} = EthForwarder.forward(body_params, header_params, opts)
        response = Jason.decode!(response.body)

        # The response should be from PotterhatNode.MockEthereumNode.RPC
        assert response["result"] == "PotterhatMockEthereumNode"
      end)

      assert log =~ "Failed to serve the RPC request"
      assert log =~ "Retrying the request with the next available node"
      assert length(ActiveNodes.all(meta.node_registry)) == 1
    end

    test "returns :no_nodes_available and logs an error when no active nodes are available" do
      {:ok, registry} = prepare_node_registry()
      header_params = %{"content-type" => "application/json"}

      body_params = %{
        "jsonrpc" => "2.0",
        "method" => "web3_clientVersion",
        "params" => [],
        "id" => :rand.uniform(999)
      }

      opts = [node_registry: registry]

      log = capture_log(fn ->
        result = EthForwarder.forward(body_params, header_params, opts)
        assert {:error, :no_nodes_available} == result
      end)

      assert log =~ "Failed to serve the RPC request"
    end
  end
end
