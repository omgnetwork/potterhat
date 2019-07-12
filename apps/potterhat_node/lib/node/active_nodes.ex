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

defmodule PotterhatNode.ActiveNodes do
  @moduledoc """
  A singleton GenServer that maintains the registry of currently active nodes.
  """
  use GenServer
  require Logger

  @type node_info() :: {node :: pid(), priority :: integer(), label :: String.t()}

  @doc """
  Starts a new instance of `ActiveNodes`.
  """
  @spec start_link(Keyword.t()) :: GenServer.on_start()
  def start_link(opts) do
    name = Keyword.get(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  @doc """
  Generate a child specification for `ActiveNodes`.
  """
  @spec child_spec(Keyword.t()) :: Supervisor.child_spec()
  def child_spec(opts) do
    id = Keyword.get(opts, :name, __MODULE__)

    %{
      id: id,
      start: {__MODULE__, :start_link, [opts]},
      type: :worker,
      restart: :permanent,
      shutdown: 5000
    }
  end

  @doc """
  Returns a list of pids of all active nodes.
  """
  @spec all() :: [node_info()]
  @spec all(GenServer.server()) :: [node_info()]
  def all(server \\ __MODULE__), do: GenServer.call(server, :all)

  @doc """
  Returns a count of all active nodes.
  """
  @spec count() :: non_neg_integer()
  @spec count(GenServer.server()) :: non_neg_integer()
  def count(server \\ __MODULE__), do: GenServer.call(server, :count)

  @doc """
  Returns the pid of the active node with the highest priority.
  """
  @spec first() :: node_info() | nil
  @spec first(GenServer.server()) :: node_info() | nil
  def first(server \\ __MODULE__), do: GenServer.call(server, :first)

  @doc """
  Registers an active node sorted against existing active nodes by its priority.
  """
  @spec register(pid(), integer(), String.t()) :: :ok
  @spec register(GenServer.server(), pid(), integer(), String.t()) :: :ok
  def register(server \\ __MODULE__, pid, priority, label) do
    GenServer.call(server, {:register, pid, priority, label})
  end

  @doc """
  Deregisters an active node.
  """
  @spec deregister(pid()) :: :ok
  @spec deregister(GenServer.server(), pid()) :: :ok
  def deregister(server \\ __MODULE__, pid) do
    GenServer.call(server, {:deregister, pid})
  end

  #
  # Server API
  #

  @doc false
  @impl true
  def init(_opts) do
    # The state is a list of node information
    {:ok, []}
  end

  @doc false
  @impl true
  def handle_call(:all, _from, nodes) do
    {:reply, nodes, nodes}
  end

  @doc false
  @impl true
  def handle_call(:count, _from, state) do
    {:reply, length(state), state}
  end

  @doc false
  @impl true
  def handle_call(:first, _from, nodes) do
    {:reply, List.first(nodes), nodes}
  end

  @doc false
  @impl true
  def handle_call({:register, pid, priority, label}, _from, nodes) do
    prepended = [{pid, priority, label} | nodes]
    nodes = Enum.sort_by(prepended, fn {_, priority, _} -> priority end)

    _ = :telemetry.execute([:active_nodes, :registered], %{num_active: length(nodes)}, %{pid: pid})
    {:reply, :ok, nodes}
  end

  @doc false
  @impl true
  def handle_call({:deregister, pid_to_delete}, _from, nodes) do
    nodes = Enum.reject(nodes, fn {pid, _priority, _label} -> pid == pid_to_delete end)
    _ = :telemetry.execute([:active_nodes, :deregistered], %{num_active: length(nodes)}, %{pid: pid_to_delete})

    {:reply, :ok, nodes}
  end
end
