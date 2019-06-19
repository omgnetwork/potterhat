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

defmodule PotterhatNode.SyncStatusTest do
  use ExUnit.Case
  import PotterhatNode.EthereumTestHelper
  alias PotterhatNode.Listener.SyncStatus

  setup do
    {:ok, rpc_url, websocket_url} = start_mock_node()

    {:ok,
     %{
       rpc_url: rpc_url,
       websocket_url: websocket_url
     }}
  end

  describe "start_link/2" do
    test "returns a pid", meta do
      {res, pid} = SyncStatus.start_link(meta.websocket_url, [])

      assert res == :ok
      assert is_pid(pid)
    end
  end

  describe "on receving websocket packets" do
    test "notifies the subsciber", meta do
      {:ok, _} = SyncStatus.start_link(meta.websocket_url, [])
      assert_receive {:"$gen_cast", {:event_received, :sync_status, _}}
    end
  end
end
