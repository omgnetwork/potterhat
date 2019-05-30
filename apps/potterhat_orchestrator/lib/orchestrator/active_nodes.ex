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

defmodule PotterhatOrchestrator.ActiveNodes do
  use GenServer
  require Logger

  @spec start_link(Keyword.t()) :: GenServer.on_start()
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]},
      type: :worker,
      restart: :permanent,
      shutdown: 5000
    }
  end

  @spec all() :: [pid()]
  def all, do: GenServer.call(__MODULE__, :all)

  @spec first() :: pid() | nil
  def first, do: GenServer.call(__MODULE__, :first)

  @doc """
  Registers an active node sorted against existing active nodes by its priority.
  """
  @spec register(pid(), integer()) :: :ok
  def register(pid, priority) do
    GenServer.call(__MODULE__, {:register, pid, priority})
  end

  @doc """
  Deregisters an active node.
  """
  @spec deregister(pid()) :: :ok
  def deregister(pid) do
    GenServer.call(__MODULE__, {:deregister, pid})
  end

  #
  # Server API
  #

  @impl true
  def init(_opts) do
    state = []
    {:ok, state}
  end

  @impl true
  def handle_call(:all, _from, state) do
    pids = Enum.map(state, fn {pid, _priority} -> pid end)
    {:reply, pids, state}
  end

  @impl true
  def handle_call(:first, _from, state) do
    first =
      case state.pids do
        [] -> nil
        [pids | _] -> elem(pids, 0)
      end

    {:reply, first, state}
  end

  @impl true
  def handle_call({:register, pid, priority}, _from, pids) do
    prepended = [{pid, priority} | pids]
    pids = Enum.sort_by(prepended, fn {_pid, priority} -> priority end)

    Logger.debug("Registered node: #{inspect(pid)}. Active nodes: #{length(pids)}.")
    {:reply, :ok, pids}
  end

  @impl true
  def handle_call({:deregister, pid_to_delete}, _from, pids) do
    pids = Enum.reject(pids, fn {pid, _priority} -> pid == pid_to_delete end)

    Logger.debug("Deregistered node: #{inspect(pid_to_delete)}. Active nodes: #{length(pids)}.")
    {:reply, :ok, pids}
  end
end
