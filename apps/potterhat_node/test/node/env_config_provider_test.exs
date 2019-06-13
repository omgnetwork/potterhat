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

defmodule PotterhatNode.EnvConfigProviderTest do
  # Cannot be asynchronous as the tests need to manipulate environment variables
  use ExUnit.Case, async: false
  alias PotterhatNode.EnvConfigProvider

  @env_prefix "POTTERHAT_NODE_"

  setup do
    #
    # Wipe all potterhat env vars so they don't intefere with the system under test.
    #
    all_envs = System.get_env()

    potterhat_env_vars =
      Enum.filter(all_envs, fn {key, _value} ->
        String.starts_with?(key, @env_prefix)
      end)

    _ = Enum.each(potterhat_env_vars, fn {key, _value} -> System.delete_env(key) end)

    #
    # Wipe all potterhat app envs so they don't intefere with the system under test.
    #

    potterhat_app_envs = Application.get_env(:potterhat_node, :nodes)
    :ok = Application.put_env(:potterhat_node, :nodes, [])

    #
    # Restore env vars and app vars to their original states.
    # We need to do this so that we don't intefere with future instances.
    #
    on_exit(fn ->
      :ok = Enum.each(potterhat_env_vars, fn {key, value} -> System.put_env(key, value) end)
      :ok = Application.put_env(:potterhat_node, :nodes, potterhat_app_envs)
    end)

    :ok
  end

  describe "get_configs/0" do
    test "returns the configs parsed from environment variables" do
      envs = %{
        id: "node_id_1",
        label: "Node 1",
        client: "geth",
        rpc: "http://localhost:8545",
        ws: "ws://localhost:8546",
        priority: "1"
      }

      :ok = set_envs(envs, 1)

      assert EnvConfigProvider.get_configs() |> length() == 1

      config = EnvConfigProvider.get_configs() |> hd()
      assert config.id == envs.id |> String.to_atom()
      assert config.label == envs.label
      assert config.client == envs.client
      assert config.rpc == envs.rpc
      assert config.ws == envs.ws
      assert config.priority == envs.priority |> String.to_integer()
    end

    test "throws an exception if partially missing env vars" do
      envs = %{
        id: "node_id_1",
        label: "Node 1",
        client: "geth",
        rpc: "http://localhost:8545",
        ws: "ws://localhost:8546",
        priority: "1"
      }

      :ok = set_envs(envs, 1)
      :ok = System.delete_env("POTTERHAT_NODE_1_RPC")

      assert_raise KeyError, fn -> EnvConfigProvider.get_configs() end
    end
  end

  defp set_envs(config, index) do
    :ok = System.put_env("POTTERHAT_NODE_#{index}_ID", Map.fetch!(config, :id))
    :ok = System.put_env("POTTERHAT_NODE_#{index}_LABEL", Map.fetch!(config, :label))
    :ok = System.put_env("POTTERHAT_NODE_#{index}_CLIENT", Map.fetch!(config, :client))
    :ok = System.put_env("POTTERHAT_NODE_#{index}_RPC", Map.fetch!(config, :rpc))
    :ok = System.put_env("POTTERHAT_NODE_#{index}_WS", Map.fetch!(config, :ws))
    :ok = System.put_env("POTTERHAT_NODE_#{index}_PRIORITY", Map.fetch!(config, :priority))

    :ok
  end

  describe "init/1" do
    test "parse the environment variables and applies to :nodes app envs" do
      envs = %{
        id: "node_id_1",
        label: "Node 1",
        client: "geth",
        rpc: "http://localhost:8545",
        ws: "ws://localhost:8546",
        priority: "1"
      }

      :ok = set_envs(envs, 1)

      assert Application.get_env(:potterhat_node, :nodes) == []

      result = EnvConfigProvider.init([])
      assert result == :ok

      nodes = Application.get_env(:potterhat_node, :nodes)
      assert length(nodes) == 1
      assert hd(nodes).id == :"#{envs.id}"
    end
  end
end
