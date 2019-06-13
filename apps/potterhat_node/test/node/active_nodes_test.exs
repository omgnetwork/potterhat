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

defmodule PotterhatNode.ActiveNodesTest do
  use ExUnit.Case
  alias PotterhatNode.ActiveNodes

  setup do
    # Starts an isolated ActiveNodes server so we can test different cases independently.
    # In real world use case we only need a single instance of ActiveNodes,
    # so we can call ActiveNodes functions without passing its pid, unlike these tests.
    {:ok, active_nodes_pid} =
      GenServer.start_link(ActiveNodes, [], name: :"active_nodes_#{:rand.uniform(99999999)}")

    {:ok, %{
      active_nodes_pid: active_nodes_pid
    }}
  end

  describe "all/1" do
    test "returns an empty list by default", meta do
      assert ActiveNodes.all(meta.active_nodes_pid) == []
    end

    test "returns a list of pids", meta do
      {:ok, node_pid_1} = Agent.start(fn -> nil end)
      {:ok, node_pid_2} = Agent.start(fn -> nil end)

      :ok = ActiveNodes.register(meta.active_nodes_pid, node_pid_1, 10)
      :ok = ActiveNodes.register(meta.active_nodes_pid, node_pid_2, 20)

      assert [node_pid_1, node_pid_2] = ActiveNodes.all(meta.active_nodes_pid)
    end
  end

  describe "first/1" do
    test "returns the pid with the top priority", meta do
      {:ok, node_pid_1} = Agent.start(fn -> nil end)
      {:ok, node_pid_2} = Agent.start(fn -> nil end)
      {:ok, node_pid_3} = Agent.start(fn -> nil end)

      :ok = ActiveNodes.register(meta.active_nodes_pid, node_pid_2, 20)
      :ok = ActiveNodes.register(meta.active_nodes_pid, node_pid_1, 10)
      :ok = ActiveNodes.register(meta.active_nodes_pid, node_pid_3, 30)

      assert ActiveNodes.first(meta.active_nodes_pid) == node_pid_1
    end

    test "returns nil if there are no active nodes", meta do
      assert ActiveNodes.first(meta.active_nodes_pid) == nil
    end
  end

  describe "register/3" do
    test "adds the given node to the registry", meta do
      {:ok, node_pid} = Agent.start(fn -> nil end)
      :ok = ActiveNodes.register(meta.active_nodes_pid, node_pid, 10)

      assert [node_pid] = ActiveNodes.all(meta.active_nodes_pid)
    end

    test "sorts the nodes by their priorities", meta do
      {:ok, node_pid_1} = Agent.start(fn -> nil end)
      {:ok, node_pid_2} = Agent.start(fn -> nil end)
      {:ok, node_pid_3} = Agent.start(fn -> nil end)

      :ok = ActiveNodes.register(meta.active_nodes_pid, node_pid_2, 20)
      :ok = ActiveNodes.register(meta.active_nodes_pid, node_pid_1, 10)
      :ok = ActiveNodes.register(meta.active_nodes_pid, node_pid_3, 30)

      assert [node_pid_1, node_pid_2, node_pid_3] = ActiveNodes.all(meta.active_nodes_pid)
    end
  end

  describe "deregister/3" do
    test "removes the matching node from the registry", meta do
      {:ok, node_pid_1} = Agent.start(fn -> nil end)
      {:ok, node_pid_2} = Agent.start(fn -> nil end)
      {:ok, node_pid_3} = Agent.start(fn -> nil end)

      :ok = ActiveNodes.register(meta.active_nodes_pid, node_pid_1, 10)
      :ok = ActiveNodes.register(meta.active_nodes_pid, node_pid_2, 20)
      :ok = ActiveNodes.register(meta.active_nodes_pid, node_pid_3, 30)

      assert ActiveNodes.deregister(meta.active_nodes_pid, node_pid_2) == :ok
      assert [node_pid_1, node_pid_3] = ActiveNodes.all(meta.active_nodes_pid)
    end
  end
end
