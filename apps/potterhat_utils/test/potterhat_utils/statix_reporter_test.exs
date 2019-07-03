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

defmodule PotterhatUtils.StatixReporterTest do
  # Async false due to changing log level
  use ExUnit.Case, async: false
  alias PotterhatUtils.StatixReporter
  alias Plug.Conn

  defmodule MockStatixServer do
    use GenServer

    def start_link(opts) do
      GenServer.start_link(__MODULE__, opts)
    end

    def get_port(pid) do
      GenServer.call(pid, :get_port)
    end

    def init(opts) do
      {:ok, socket, port} = start_server([:binary, active: true], 8125)
      {:ok, %{socket: socket, port: port, test_pid: opts[:pid]}}
    end

    def handle_call(:get_port, _from, state) do
      {:reply, state.port, state}
    end

    def handle_info({:udp, socket, _, _, packet}, %{socket: socket, test_pid: test_pid} = state) do
      _ = send(test_pid, {:statix_event, packet})
      {:noreply, state}
    end

    defp start_server(opts), do: start_server(opts, Enum.random(30_000..40_000))

    defp start_server(opts, port) do
      case :gen_udp.open(port) do
        {:ok, socket} -> {:ok, socket, port}
        {:error, :eaddrinuse} -> start_server(opts)
      end
    end
  end

  defmodule TestStatix do
    use Statix, runtime_config: true
  end

  setup do
    handler_id = "test_rpc_event_logger_#{:rand.uniform(999_999)}"

    # Sets up telemetry handler

    :ok = :telemetry.attach_many(
      handler_id,
      StatixReporter.supported_events(),
      &StatixReporter.handle_event/4,
      nil
    )

    :ok = on_exit(fn -> :telemetry.detach(handler_id) end)

    # Sets up mock Statix server

    {:ok, pid} = MockStatixServer.start_link(pid: self())
    port = MockStatixServer.get_port(pid)
    :ok = Application.put_env(:statix, TestStatix, port: port)
    :ok = TestStatix.connect()

    :ok
  end

  describe "supported_events/0" do
    test "returns a list of telemetry events" do
      Enum.each(StatixReporter.supported_events(), fn event ->
        assert is_list(event)
        assert Enum.all?(event, fn item -> is_atom(item) end)
      end)
    end
  end

  describe "handle_event/4" do
    test "sends metrics for [:active_nodes, :registered]" do
      measurements = %{num_active: 10}
      :telemetry.execute([:active_nodes, :registered], measurements, meta())

      assert_receive {:statix_event, 'potterhat.active_nodes.num_registered:1|c|#node_id:some_node_id'}
      assert_receive {:statix_event, 'potterhat.active_nodes.total_active:10|g|#node_id:some_node_id'}
    end

    test "sends metrics for [:active_nodes, :deregistered]" do
      measurements = %{num_active: 10}
      :telemetry.execute([:active_nodes, :deregistered], measurements, meta())

      assert_receive {:statix_event, 'potterhat.active_nodes.num_deregistered:1|c|#node_id:some_node_id'}
      assert_receive {:statix_event, 'potterhat.active_nodes.total_active:10|g|#node_id:some_node_id'}
    end

    test "sends metrics for [:rpc, :request, :start]" do
      meta = meta(conn: %Conn{assigns: %{eth_method: "eth_method"}})
      :telemetry.execute([:rpc, :request, :start], measurements(), meta)

      assert_receive {:statix_event, 'potterhat.rpc.num_requests:1|c|#node_id:some_node_id,eth_method:eth_method'}
    end

    test "sends metrics for [:rpc, :request, :stop]" do
      measurements = %{duration: 123}
      meta = meta(conn: %Conn{assigns: %{eth_method: "eth_method"}})
      :telemetry.execute([:rpc, :request, :stop], measurements, meta)

      assert_receive {:statix_event, 'potterhat.rpc.response_time:123|ms|#node_id:some_node_id,eth_method:eth_method'}
    end

    test "sends metrics for [:rpc, :request, :success]" do
      meta = meta(conn: %Conn{assigns: %{eth_method: "eth_method"}})
      :telemetry.execute([:rpc, :request, :success], measurements(), meta)

      assert_receive {:statix_event, 'potterhat.rpc.num_success:1|c|#node_id:some_node_id,eth_method:eth_method'}
    end

    test "sends metrics for [:rpc, :request, :failed]" do
      meta = meta(conn: %Conn{assigns: %{eth_method: "eth_method"}})
      :telemetry.execute([:rpc, :request, :failed], measurements(), meta)

      assert_receive {:statix_event, 'potterhat.rpc.num_failed:1|c|#node_id:some_node_id,eth_method:eth_method'}
    end

    # Set capture_log to ignore the failed_over error log
    @moduletag capture_log: true
    test "sends metrics for [:rpc, :request, :failed_over]" do
      meta = meta(body_params: %{"method" => "eth_method"})
      :telemetry.execute([:rpc, :request, :failed_over], measurements(), meta)
      assert_receive {:statix_event, 'potterhat.rpc.num_failed_over:1|c|#node_id:some_node_id,eth_method:eth_method'}
    end

    test "sends metrics for [:event_listener, :new_head, :subscribe_success]" do
      :telemetry.execute([:event_listener, :new_head, :subscribe_success], measurements(), meta())
      assert_receive {:statix_event, 'potterhat.events.new_head.num_subscribe_success:1|c|#node_id:some_node_id'}
    end

    test "sends metrics for [:event_listener, :new_head, :subscribe_failed]" do
      :telemetry.execute([:event_listener, :new_head, :subscribe_failed], measurements(), meta())
      assert_receive {:statix_event, 'potterhat.events.new_head.num_subscribe_failed:1|c|#node_id:some_node_id'}
    end

    test "sends metrics for [:event_listener, :new_head, :head_received]" do
      meta = meta(block_number: 123)
      :telemetry.execute([:event_listener, :new_head, :head_received], measurements(), meta)

      assert_receive {:statix_event, 'potterhat.events.new_head.num_received:1|c|#node_id:some_node_id'}
      assert_receive {:statix_event, 'potterhat.events.new_head.block_number_received:123|g|#node_id:some_node_id'}
    end

    test "sends metrics for [:event_listener, :log, :subscribe_success]" do
      :telemetry.execute([:event_listener, :log, :subscribe_success], measurements(), meta())
      assert_receive {:statix_event, 'potterhat.events.log.num_subscribe_success:1|c|#node_id:some_node_id'}
    end

    test "sends metrics for [:event_listener, :log, :subscribe_failed]" do
      :telemetry.execute([:event_listener, :log, :subscribe_failed], measurements(), meta())
      assert_receive {:statix_event, 'potterhat.events.log.num_subscribe_failed:1|c|#node_id:some_node_id'}
    end

    test "sends metrics for [:event_listener, :log, :log_received]" do
      meta = meta(block_number: 123)
      :telemetry.execute([:event_listener, :log, :log_received], measurements(), meta)

      assert_receive {:statix_event, 'potterhat.events.log.num_received:1|c|#node_id:some_node_id'}
    end

    test "sends metrics for [:event_listener, :new_pending_transaction, :subscribe_success]" do
      :telemetry.execute([:event_listener, :new_pending_transaction, :subscribe_success], measurements(), meta())
      assert_receive {:statix_event, 'potterhat.events.new_pending_transaction.num_subscribe_success:1|c|#node_id:some_node_id'}
    end

    test "sends metrics for [:event_listener, :new_pending_transaction, :subscribe_failed]" do
      :telemetry.execute([:event_listener, :new_pending_transaction, :subscribe_failed], measurements(), meta())
      assert_receive {:statix_event, 'potterhat.events.new_pending_transaction.num_subscribe_failed:1|c|#node_id:some_node_id'}
    end

    test "sends metrics for [:event_listener, :new_pending_transaction, :transaction_received]" do
      meta = meta(block_number: 123)
      :telemetry.execute([:event_listener, :new_pending_transaction, :transaction_received], measurements(), meta)

      assert_receive {:statix_event, 'potterhat.events.new_pending_transaction.num_received:1|c|#node_id:some_node_id'}
    end

    test "sends metrics for [:event_listener, :sync_status, :subscribe_success]" do
      meta = meta(node_id: :some_node_id, pid: self())
      :telemetry.execute([:event_listener, :sync_status, :subscribe_success], measurements(), meta)

      assert_receive {:statix_event, 'potterhat.events.sync_status.num_subscribe_success:1|c|#node_id:some_node_id'}
    end

    test "sends metrics for [:event_listener, :sync_status, :subscribe_failed]" do
      meta = meta(block_number: 123)
      :telemetry.execute([:event_listener, :sync_status, :subscribe_failed], measurements(), meta)

      assert_receive {:statix_event, 'potterhat.events.sync_status.num_subscribe_failed:1|c|#node_id:some_node_id'}
    end

    test "sends metrics for [:event_listener, :sync_status, :sync_started]" do
      meta = meta(block_number: 123)
      :telemetry.execute([:event_listener, :sync_status, :sync_started], measurements(), meta)

      assert_receive {:statix_event, 'potterhat.events.sync_status.num_sync_started:1|c|#node_id:some_node_id'}
      assert_receive {:statix_event, 'potterhat.events.sync_status.num_received:1|c|#node_id:some_node_id'}
    end

    test "sends metrics for [:event_listener, :sync_status, :sync_stopped]" do
      measurements = measurements(current_block: 123, highest_block: 321)
      :telemetry.execute([:event_listener, :sync_status, :sync_stopped], measurements, meta())

      assert_receive {:statix_event, 'potterhat.events.sync_status.num_sync_stopped:1|c|#node_id:some_node_id'}
      assert_receive {:statix_event, 'potterhat.events.sync_status.num_received:1|c|#node_id:some_node_id'}
      assert_receive {:statix_event, 'potterhat.events.sync_status.current_block:123|g|#node_id:some_node_id'}
      assert_receive {:statix_event, 'potterhat.events.sync_status.highest_block:321|g|#node_id:some_node_id'}
    end
  end

  defp measurements(extras \\ []) do
    default_measurements = %{}
    Enum.reduce(extras, default_measurements, fn {key, value}, meta -> Map.put(meta, key, value) end)
  end

  defp meta(extras \\ []) do
    default_meta = %{node_id: :some_node_id, pid: self()}
    Enum.reduce(extras, default_meta, fn {key, value}, meta -> Map.put(meta, key, value) end)
  end
end
