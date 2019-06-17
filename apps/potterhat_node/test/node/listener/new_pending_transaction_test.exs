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

defmodule PotterhatNode.NewPendingTransactionTest do
  use ExUnit.Case
  import PotterhatNode.EthereumTestHelper
  alias PotterhatNode.Listener.NewPendingTransaction
  alias PotterhatNode.MockNode

  setup do
    {:ok, rpc_url, websocket_url} = start_mock_node()

    {:ok, %{
      rpc_url: rpc_url,
      websocket_url: websocket_url
    }}
  end

  describe "start_link/2" do
    test "returns a pid", meta do
      {:ok, node_pid} = GenServer.start_link(MockNode, [])
      {res, pid} = NewPendingTransaction.start_link(meta.websocket_url, subscriber: node_pid)

      assert res == :ok
      assert is_pid(pid)
    end
  end

  describe "on receving websocket packets" do
    test "notifies the subsciber", meta do
      {:ok, node_pid} = GenServer.start_link(MockNode, [])

      assert MockNode.get_events(node_pid) == []

      # When the listener starts up, it should automatically make a subscription,
      # and we should get one response in return.
      {:ok, _} = NewPendingTransaction.start_link(meta.websocket_url, subscriber: node_pid)

      # I know, this sucks right?
      # Feel free to refactor into a synchronous wait if there is a way.
      Process.sleep(100)

      events = MockNode.get_events(node_pid)

      assert length(events) == 1
      assert {:event_received, :new_pending_transactions, _} = hd(events)
    end
  end
end
