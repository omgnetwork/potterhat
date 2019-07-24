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

defmodule PotterhatNode do
  @moduledoc """
  The Potterhat's sub-application responsible for listening to events,
  and exchange data to/from Ethereum nodes.
  """

  @doc """
  Retrieve the list of all node configurations.
  """
  @spec get_node_configs() :: [%PotterhatNode.NodeConfig{}]
  def get_node_configs do
    Application.get_env(:potterhat_node, :nodes)
  end
end
