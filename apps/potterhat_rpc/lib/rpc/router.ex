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
  require Logger
  alias PotterhatNode.{ActiveNodes, Node}
  alias PotterhatRPC.ErrorHandler

  plug(Plug.Logger)
  plug(Plug.Parsers, parsers: [:json], json_decoder: Jason)

  plug(:match)
  plug(:dispatch)

  get "/" do
    send_resp(conn, 200, Jason.encode!(%{status: true}))
  end

  # Forward all POST requests to the node and relay the response back to the requester.
  post "/" do
    case node_request(conn.body_params, conn.req_headers) do
      {:ok, response} ->
        # `resp_headers` is reset to `[]` ensure only node's headers are returned.
        conn
        |> Map.put(:resp_headers, [])
        |> merge_resp_headers(response.headers)
        |> send_resp(response.status_code, response.body)

      {:error, code} ->
        ErrorHandlers.send_resp(conn, code, conn.body_params.id)
    end
  end

  match _ do
    send_resp(conn, 404, "Not found.")
  end

  defp node_request(_body_params, _header_params, []) do
    {:error, :no_nodes_available}
  end

  defp node_request(body_params, header_params) do
    node_id = ActiveNodes.first()

    case Node.rpc_request(node_id, body_params, header_params) do
      {:ok, response} ->
        label = Node.get_label(node_id)
        Logger.debug("Serving the RPC request from #{label}.")
        {:ok, response}

      {:error, error} ->
        ActiveNodes.deregister(node_id)
        Logger.error("Failed to serve the RPC request: #{inspect(error)}.")

        case ActiveNodes.first() do
          nil ->
            {:error, :no_nodes_available}

          _ ->
            Logger.error("Retrying the request with the next available nonde.")
            node_request(body_params, header_params)
        end
    end
  end
end
