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

defmodule PotterhatMetrics.Collector do
  @moduledoc """
  Collects periodic metrics.

  Passing the option `interval_ms: 0` will disable scheduled reporting.
  """
  use GenServer
  alias PotterhatNode.ActiveNodes

  @enabled [
    :active_nodes,
    :configured_nodes
  ]

  @doc """
  Starts and links a new Collector server.
  """
  @spec start_link(Keyword.t()) :: GenServer.on_start()
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts)
  end

  @doc """
  Manually triggers a collection.
  """
  @spec collect(GenServer.server()) :: any()
  def collect(server), do: Process.send(server, :collect, [])

  @doc false
  @spec init(Keyword.t()) :: {:ok, %{:interval_ms => non_neg_integer()}}
  def init(opts) do
    state = %{
      interval_ms: Keyword.fetch!(opts, :interval_ms)
    }

    # The interval might be long. Don't wait to start reporting, do it the next second.
    _ = if state.interval_ms > 0, do: schedule_work(1000)

    {:ok, state}
  end

  @doc false
  def handle_info(:collect, state) do
    _ = Enum.each(@enabled, &report/1)

    _ = if state.interval_ms > 0, do: schedule_work(state.interval_ms)
    {:noreply, state}
  end

  defp schedule_work(delay) do
    Process.send_after(self(), :collect, delay)
  end

  defp report(:active_nodes) do
    count = ActiveNodes.count()
    :telemetry.execute([:periodic_metrics, :active_nodes, :collected], %{total: count}, %{})
  end

  defp report(:configured_nodes) do
    count = PotterhatNode.count()
    :telemetry.execute([:periodic_metrics, :configured_nodes, :collected], %{total: count}, %{})
  end
end
