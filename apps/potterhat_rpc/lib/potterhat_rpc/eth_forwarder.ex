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

defmodule PotterhatRPC.EthForwarder do
  @moduledoc """
  Forward requests to a registered Ethereum node.
  """
  require Logger
  alias PotterhatNode.{ActiveNodes, Node}

  @spec forward(map(), map(), Keyword.t()) ::
          {:ok, %PotterhatNode.Node.RPCResponse{}} | {:error, :no_nodes_available}
  def forward(body_params, header_params, opts \\ []) do
    node_registry = Keyword.get(opts, :node_registry, ActiveNodes)
    node_id = ActiveNodes.first(node_registry)

    case Node.rpc_request(node_id, body_params, header_params) do
      {:ok, response} ->
        _ = Logger.debug("Serving the RPC request from #{Node.get_label(node_id)}.")
        {:ok, response}

      {:error, error} ->
        :ok = ActiveNodes.deregister(node_registry, node_id)
        _ = Logger.error("Failed to serve the RPC request: #{inspect(error)}.")

        case ActiveNodes.first(node_registry) do
          nil ->
            {:error, :no_nodes_available}

          _ ->
            _ = Logger.error("Retrying the request with the next available node.")
            forward(body_params, header_params, opts)
        end
    end
  end
end
