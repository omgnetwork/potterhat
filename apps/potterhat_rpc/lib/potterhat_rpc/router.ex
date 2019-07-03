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

defmodule PotterhatRPC.Router do
  @moduledoc """
  Serves RPC requests.
  """
  use Plug.Router
  alias PotterhatNode.ActiveNodes
  alias PotterhatRPC.{ErrorHandler, EthForwarder}
  alias Plug.Conn

  plug(Plug.Logger)

  plug(:match)
  plug(Plug.Telemetry, event_prefix: [:rpc, :request])
  plug(Plug.Parsers, parsers: [:json], json_decoder: Jason)
  plug(:store_eth_method)
  plug(:dispatch)

  get "/" do
    send_resp(
      conn,
      200,
      Jason.encode!(%{
        status: true,
        potterhat_version: Application.get_env(:potterhat_rpc, :version),
        nodes: %{
          total: length(PotterhatNode.get_node_configs()),
          active: length(ActiveNodes.all())
        }
      })
    )
  end

  # Forward all POST requests to the node and relay the response back to the requester.
  post "/" do
    case EthForwarder.forward(conn.body_params, conn.req_headers) do
      {:ok, response} ->
        _ = :telemetry.execute([:rpc, :request, :success], %{}, %{conn: conn})

        # `resp_headers` is reset to `[]` ensure only node's headers are returned.
        conn
        |> Map.put(:resp_headers, [])
        |> merge_resp_headers(response.headers)
        |> send_resp(response.status_code, response.body)

      {:error, code} ->
        _ = :telemetry.execute([:rpc, :request, :failed], %{}, %{conn: conn, error_code: code})
        ErrorHandler.send_resp(conn, code)
    end
  end

  defp store_eth_method(conn, opts) do
    Conn.assign(conn, :eth_method, conn.body_params["method"])
  end
end
