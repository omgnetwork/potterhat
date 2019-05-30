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

defmodule PotterhatNode.NodeConfig do
  @enforce_keys [:id, :label, :client, :rpc, :ws, :priority]
  defstruct [:id, :label, :client, :rpc, :ws, :priority]

  @doc """
  Builds a NodeConfig struct from the given map of inputs with string keys.
  """
  def from_input_map!(map) do
    # The "id" is converted to atom here so it can be used as GenServer identifier etc.
    # The String.to_atom/1 should be safe here as the node configurations should
    # only be set by administrators.
    %__MODULE__{
      id: Map.fetch!(map, "id") |> String.to_atom(),
      label: Map.fetch!(map, "label"),
      client: Map.fetch!(map, "client"),
      rpc: Map.fetch!(map, "rpc"),
      ws: Map.fetch!(map, "ws"),
      priority: Map.fetch!(map, "priority") |> String.to_integer()
    }
  end
end
