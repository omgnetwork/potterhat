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
    nodes = ActiveNodes.all(node_registry)

    do_forward(nodes, body_params, header_params)
  end

  defp do_forward([{pid, _priority, label} | remaining], body_params, header_params) do
    _ = Logger.debug("Trying to serve the request from #{label}.")

    case Node.rpc_request(pid, body_params, header_params) do
      {:ok, response} ->
        _ = Logger.info("Served the RPC request from #{label}.")
        {:ok, response}

      {:error, error} ->
        _ = Logger.error("Failed to serve the RPC request from #{label}: #{inspect(error)}.")
        do_forward(remaining, body_params, header_params)
    end
  end

  defp do_forward([], _, _) do
    _ = Logger.warn("Exhausted all nodes to serve the RPC request from.")
    {:error, :no_nodes_available}
  end
end
