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

defmodule PotterhatRPC.ErrorResponse do
  @moduledoc """
  Prepares an RPC error response.
  """
  alias Plug.Conn

  def send_resp(conn, :no_nodes_available) do
    # 502 Bad Gateway
    # This error response means that the server, while working as a gateway
    # to get a response needed to handle the request, got an invalid response.
    # Ref: https://developer.mozilla.org/en-US/docs/Web/HTTP/Status
    do_send_resp(conn, -32_099, "No backend nodes available.")
  end

  defp do_send_resp(conn, code, message) do
    payload =
      code
      |> render(message)
      |> Jason.encode!()

    # Per JSON-RPC specs, errors always return with HTTP status 500
    # Ref: https://www.jsonrpc.org/historical/json-rpc-over-http.html#errors
    Conn.send_resp(conn, 500, payload)
  end

  # For error code, see: https://github.com/ethereum/wiki/wiki/JSON-RPC-Error-Codes-Improvement-Proposal
  defp render(code, message) do
    %{
      "jsonrpc" => "2.0",
      "error" => %{
        "code" => code,
        "message" => message
      },
      "id" => 1
    }
  end
end
