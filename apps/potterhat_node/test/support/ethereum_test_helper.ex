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

defmodule Potterhat.Node.EthereumTestHelper do
  alias Potterhat.Node.MockEthereumNode

  defmodule MockSubscriber do
    use GenServer
    @behaviour Potterhat.Node.Subscriber

    def init(_opts) do
      {:ok, nil}
    end

    def handle_event(emitter, message) do
      :noop
    end
  end

  # Using macro here to inject on_exit/1 into the setup
  defmacro start_mock_node do
    quote do
      {:ok, {server_ref, rpc_url, websocket_url}} = MockEthereumNode.start(self())
      on_exit(fn -> MockEthereumNode.shutdown(server_ref) end)

      {:ok, rpc_url, websocket_url}
    end
  end

  # Using macro here to inject on_exit/1 into the setup
  defmacro start_mock_subscriber do
    quote do
      {:ok, pid} = MockSubscriber.start_link()
      on_exit(fn -> MockSubscriber.shutdown(pid) end)

      {:ok, pid}
    end
  end
end
