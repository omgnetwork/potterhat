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

defmodule PotterhatRPC.RouterTest do
  use PotterhatRPC.ConnCase, async: true
  import PotterhatNode.EthereumTestHelper
  import PotterhatUtils.TelemetryTestHelper
  alias PotterhatNode.{ActiveNodes, Node}
  alias PotterhatRPC.Router

  setup do
    {:ok, rpc_url, websocket_url} = start_mock_node()

    config = %PotterhatNode.NodeConfig{
      id: String.to_atom("test_eth_forwarder_#{:rand.uniform(999_999_999)}"),
      label: "A mock node for EthForwarderTest",
      client_type: :geth,
      rpc: rpc_url,
      ws: websocket_url,
      priority: 10,
      node_registry: ActiveNodes
    }

    {:ok, _pid} = Node.start_link(config)

    # The nodes take some time to intialize, so we wait for 100ms.
    _ = Process.sleep(100)

    :ok
  end

  describe "GET /" do
    test "returns status, version and node stats" do
      response =
        Router
        |> call(:get, "/")
        |> json_response()

      assert %{
               "status" => true,
               "potterhat_version" => _,
               "nodes" => %{
                 "total" => _,
                 "active" => _
               }
             } = response
    end
  end

  describe "POST /" do
    test "returns response from the active node" do
      body_params = %{
        "jsonrpc" => "2.0",
        "method" => "web3_clientVersion",
        "params" => [],
        "id" => :rand.uniform(999)
      }

      response =
        Router
        |> call(:post, "/", body_params)
        |> json_response()

      # The response should be from PotterhatNode.MockEthereumNode.RPC
      assert response["result"] == "PotterhatMockEthereumNode"
    end

    test "returns an error response when received an error from forwarding" do
      body_params = %{
        "jsonrpc" => "2.0",
        "method" => "some invalid method",
        "params" => [],
        "id" => :rand.uniform(999)
      }

      response =
        Router
        |> call(:post, "/", body_params)
        |> json_response()

      assert response["error"]["code"] == -32_601
      assert response["error"]["message"] == "Method not found"
    end

    test "emits Plug.Telemetry events" do
      listen_telemetry([:rpc, :request, :start])
      listen_telemetry([:rpc, :request, :success])
      listen_telemetry([:rpc, :request, :stop])

      body_params = %{
        "jsonrpc" => "2.0",
        "method" => "web3_clientVersion",
        "params" => [],
        "id" => :rand.uniform(999)
      }

      _ =
        Router
        |> call(:post, "/", body_params)
        |> json_response()

      assert_telemetry([:rpc, :request, :start])
      assert_telemetry([:rpc, :request, :success])
      assert_telemetry([:rpc, :request, :stop])
    end
  end
end
