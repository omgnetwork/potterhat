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

defmodule PotterhatMetrics.CollectorTest do
  # Disable async to prevent receiving telemetry events from other tests
  use ExUnit.Case, async: false
  import PotterhatUtils.TelemetryTestHelper
  alias PotterhatMetrics.Collector

  setup_all do
    # Setting `async: false` unfortunately is not enough. There may be some lingering
    # tasks that have just emitted telemetry events.
    #
    # So let's wait for 1 second for all those events to be fired. Then we can test
    # without worrying about side effect telemetries from other tests and running processes.
    #
    # This is a one-time sleep per the whole module, so the impact on test time
    # should be minimal.
    _ = Process.sleep(1000)
  end

  describe "start_link/2" do
    test "returns a pid" do
      {:ok, pid} = GenServer.start_link(Collector, interval_ms: 60 * 60 * 1000)
      assert is_pid(pid)
    end

    test "emits telemetry events after start" do
      listen_telemetry([:periodic_metrics, :active_nodes, :collected])
      listen_telemetry([:periodic_metrics, :configured_nodes, :collected])

      # Set interval to 1 hour so it doesn't intefere with this test
      {:ok, pid} = GenServer.start_link(Collector, interval_ms: 60 * 60 * 1000)
      :ok = Process.sleep(1000)

      assert_telemetry([:periodic_metrics, :active_nodes, :collected])
      assert_telemetry([:periodic_metrics, :configured_nodes, :collected])
      GenServer.stop(pid)
    end

    test "does not emit telemetry events when passing interval_ms: 0" do
      listen_telemetry([:periodic_metrics, :active_nodes, :collected])
      listen_telemetry([:periodic_metrics, :configured_nodes, :collected])

      {:ok, pid} = GenServer.start_link(Collector, interval_ms: 0)
      :ok = Process.sleep(1000)

      refute_telemetry([:periodic_metrics, :active_nodes, :collected])
      refute_telemetry([:periodic_metrics, :configured_nodes, :collected])
      GenServer.stop(pid)
    end
  end

  describe "collect/1" do
    test "emits [:periodic_metrics, :active_nodes, :collected] event" do
      listen_telemetry([:periodic_metrics, :active_nodes, :collected])
      refute_telemetry([:periodic_metrics, :active_nodes, :collected])

      # Disable the interval so we could manually trigger the collection.
      {:ok, pid} = GenServer.start_link(Collector, interval_ms: 0)
      :ok = Collector.collect(pid)

      assert_telemetry([:periodic_metrics, :active_nodes, :collected])
      GenServer.stop(pid)
    end

    test "emits [:periodic_metrics, :configured_nodes, :collected] event" do
      listen_telemetry([:periodic_metrics, :configured_nodes, :collected])
      refute_telemetry([:periodic_metrics, :configured_nodes, :collected])

      # Disable the interval so we could manually trigger the collection.
      {:ok, pid} = GenServer.start_link(Collector, interval_ms: 0)
      :ok = Collector.collect(pid)

      assert_telemetry([:periodic_metrics, :configured_nodes, :collected])
      GenServer.stop(pid)
    end
  end
end
