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

defmodule PotterhatRPC.ErrorHandler do
  @moduledoc """
  Prepares an RPC error response.
  """
  alias Plug.Conn

  @errors %{
    no_nodes_available: %{
      code: -32_099,
      message: "No backend nodes available."
    }
  }

  def send_resp(conn, code, request_id) do
    error = Map.fetch!(@errors, code)

    payload =
      error.code
      |> render(error.message, request_id)
      |> Jason.encode!()

    # Per JSON-RPC specs, errors always return with HTTP status 500
    # Ref: https://www.jsonrpc.org/historical/json-rpc-over-http.html#errors
    Conn.send_resp(conn, 500, payload)
  end

  # For error response format, see: https://github.com/ethereum/EIPs/blob/master/EIPS/eip-1474.md
  defp render(code, message, request_id) do
    %{
      "id" => request_id,
      "jsonrpc" => "2.0",
      "error" => %{
        "code" => code,
        "message" => message
      }
    }
  end
end
