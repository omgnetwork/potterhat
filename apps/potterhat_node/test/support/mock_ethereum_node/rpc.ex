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

defmodule Potterhat.Node.MockEthereumNode.RPC do
  use Plug.Router

  plug(:match)
  plug(:dispatch)

  post "/" do
    response = Jason.encode!(%{
      "id" => 67,
      "jsonrpc" => "2.0",
      "result" => "Mist/v0.9.3/darwin/go1.4.1"
    })

    send_resp(conn, 200, response)
  end

  match _ do
    send_resp(conn, 200, "Hello from plug")
  end
end
