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
  import PotterhatNode.EthereumTestHelper
  alias PotterhatNode.{ActiveNodes, Node}
  alias PotterhatRPC.EthForwarder

  #
  # Test setup
  #

  setup do
    # {:ok, registry_pid} = prepare_node_registry()

    # {:ok, pid_1, config_1} = prepare_mock_node(node_registry: registry_pid, priority: 10)
    # {:ok, pid_2, config_2} = prepare_mock_node(node_registry: registry_pid, priority: 20)

    {:ok, _} = prepare_mock_node(priority: 10)
    {:ok, _} = prepare_mock_node(priority: 20)

    # The nodes take some time to intialize, so we wait for 100ms.
    _ = Process.sleep(100)

    :ok
  end

  defp prepare_mock_node(opts) do
    {:ok, rpc_url, websocket_url} = start_mock_node()

    config =
      %PotterhatNode.NodeConfig{
        id: String.to_atom("test_eth_forwarder_#{:rand.uniform(999_999_999)}"),
        label: "A mock node for EthForwarderTest",
        client_type: :geth,
        rpc: rpc_url,
        ws: websocket_url,
        priority: Keyword.get(opts, :priority, 100),
        node_registry: ActiveNodes
        # node_registry: Keyword.get(opts, :node_registry, ActiveNodes)
      }

    # {:ok, pid} = Node.start_link(config)
    # {:ok, pid, config}
    Node.start_link(config)
  end

  #
  # Actual tests
  #

  describe "sanity test the mock ethereum node" do
    test "has at least one active nodes" do
      assert length(ActiveNodes.all()) >= 1
    end
  end

  describe "POST /" do
    test "returns response from the active node" do
      req_id = 1234

      body_params = %{
        "jsonrpc" => "2.0",
        "method" => "web3_clientVersion",
        "params" => [],
        "id" => req_id
      }

      response =
        EthForwarder
        |> call(:post, "/", body_params)
        |> json_response()

      # The response should be from PotterhatNode.MockEthereumNode.RPC
      assert response["result"] == "PotterhatMockEthereumNode"
    end

    test "returns response from the next active node when the first is not available"

    test "returns :no_nodes_available error when no active nodes are available"
  end
end
