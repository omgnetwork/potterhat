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
  @spec all() :: [node :: pid()]
  @spec all(server :: pid() | module()) :: [node :: pid()]
  def all(server \\ __MODULE__), do: GenServer.call(server, :all)

  @doc """
  Returns the pid of the active node with the highest priority.
  """
  @spec first() :: pid() | nil
  @spec first(server :: pid() | module()) :: pid() | nil
  def first(server \\ __MODULE__), do: GenServer.call(server, :first)

  @doc """
  Registers an active node sorted against existing active nodes by its priority.
  """
  @spec register(node :: pid(), priority :: integer()) :: :ok
  @spec register(server :: pid() | module(), node :: pid(), priority :: integer()) :: :ok
  def register(server \\ __MODULE__, pid, priority) do
    GenServer.call(server, {:register, pid, priority})
  end

  @doc """
  Deregisters an active node.
  """
  @spec deregister(node :: pid()) :: :ok
  @spec deregister(server :: pid() | module(), node :: pid()) :: :ok
  def deregister(server \\ __MODULE__, pid) do
    GenServer.call(server, {:deregister, pid})
  end

  #
  # Server API
  #

  @doc false
  @impl true
  def init(_opts) do
    state = []
    {:ok, state}
  end

  @doc false
  @impl true
  def handle_call(:all, _from, state) do
    pids = Enum.map(state, fn {pid, _priority} -> pid end)
    {:reply, pids, state}
  end

  @doc false
  @impl true
  def handle_call(:first, _from, state) do
    first =
      case state do
        [] -> nil
        [pids | _] -> elem(pids, 0)
      end

    {:reply, first, state}
  end

  @doc false
  @impl true
  def handle_call({:register, pid, priority}, _from, pids) do
    prepended = [{pid, priority} | pids]
    pids = Enum.sort_by(prepended, fn {_pid, priority} -> priority end)

    _ = Logger.debug("Registered node: #{inspect(pid)}. Active nodes: #{length(pids)}.")
    {:reply, :ok, pids}
  end

  @doc false
  @impl true
  def handle_call({:deregister, pid_to_delete}, _from, pids) do
    pids = Enum.reject(pids, fn {pid, _priority} -> pid == pid_to_delete end)

    _ = Logger.debug("Deregistered node: #{inspect(pid_to_delete)}. Active nodes: #{length(pids)}.")
    {:reply, :ok, pids}
  end
end
