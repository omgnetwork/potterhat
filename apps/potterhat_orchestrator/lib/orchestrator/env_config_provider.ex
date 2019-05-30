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

defmodule PotterhatOrchestrator.EnvConfigProvider do
  @moduledoc """
  A Mix.Releases-compatible config provider that converts
  Potterhat-related environment variables into application configs.
  """
  use Mix.Releases.Config.Provider
  alias PotterhatNode.NodeConfig
  require Logger

  @doc """
  Initialize the nodes configuration into the application.
  """
  @spec init(any()) :: :ok | no_return()
  def init(_opts) do
    __MODULE__.get_configs() |> apply()
  end

  @doc """
  Returns the nodes configuration.
  """
  @spec get_configs() :: map() | no_return()
  def get_configs do
    System.get_env()
    |> parse()
    |> build_configs!()
  end

  # Parses the environment variables. This function takes in the result from System.get_env()
  # and returns a list of parsed node configs.
  #
  # From:
  # %{
  #   "POTTERHAT_NODE_1_ID" => "node_one",
  #   "POTTERHAT_NODE_1_LABEL" => "Node One",
  #   ..
  #   "POTTERHAT_NODE_2_ID" => "node_two",
  #   "POTTERHAT_NODE_2_LABEL" => "Node Two",
  #   ..
  # }
  #
  # Into:
  # [
  #   %{
  #     "id" => "node_one",
  #     "label" => "Node One",
  #     ..
  #   },
  #   %{
  #     "id" => "node_two",
  #     "label" => "Node Two",
  #     ..
  #   }
  #   ..
  # ]
  defp parse(envs) do
    envs
    |> Enum.reduce(%{}, fn {env, value}, nodes_by_index ->
      case Regex.run(~r/POTTERHAT_NODE_(\d+)_(\w+)/, env, capture: :all_but_first) do
        [index, key] ->
          key = String.downcase(key)
          _ = Logger.info("#{env} parsed as index: #{index}, key: #{key}.")
          Map.update(nodes_by_index, index, %{key => value}, &Map.put(&1, key, value))

        nil ->
          _ = Logger.debug("Skipped #{env} from node configurations.")
          nodes_by_index
      end
    end)
    |> Map.values()
  end

  # Build proper nodes config from the input maps
  # Throws error if keys are missing from the input maps
  defp build_configs!(input_maps) do
    Enum.map(input_maps, &NodeConfig.from_input_map!/1)
  end

  # Apply the nodes configuration to the application
  defp apply(nodes) do
    Application.put_env(:potterhat_orchestrator, :nodes, nodes)
  end
end
