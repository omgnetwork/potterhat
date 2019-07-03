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

defmodule PotterhatNode.EventLoggerTest do
  # Async false due to changing log level
  use ExUnit.Case, async: false
  import ExUnit.CaptureLog
  alias PotterhatNode.EventLogger

  setup do
    handler_id = "test_rpc_event_logger_#{:rand.uniform(999_999)}"

    :ok =
      :telemetry.attach_many(
        handler_id,
        EventLogger.supported_events(),
        &EventLogger.handle_event/4,
        nil
      )

    :ok = on_exit(fn -> :telemetry.detach(handler_id) end)

    log_level = Logger.level()
    on_exit(fn -> Logger.configure(level: log_level) end)

    :ok
  end

  describe "supported_events/0" do
    test "returns a list of telemetry events" do
      Enum.each(EventLogger.supported_events(), fn event ->
        assert is_list(event)
        assert Enum.all?(event, fn item -> is_atom(item) end)
      end)
    end
  end

  describe "handle_event/4" do
    test "logs a debug message for [:active_nodes, :registered]" do
      :ok = Logger.configure(level: :debug)

      measurements = %{
        num_active: 2
      }

      meta = %{
        node_id: :some_node_id,
        pid: self()
      }

      assert capture_log(fn ->
               :telemetry.execute([:active_nodes, :registered], measurements, meta)
             end) =~ "[debug] some_node_id: Registered node:"
    end

    test "logs a debug message for [:active_nodes, :deregistered]" do
      :ok = Logger.configure(level: :debug)

      measurements = %{
        num_active: 1
      }

      meta = %{
        node_id: :some_node_id,
        pid: self()
      }

      assert capture_log(fn ->
               :telemetry.execute([:active_nodes, :deregistered], measurements, meta)
             end) =~ "[debug] some_node_id: Deregistered node:"
    end

    test "logs an error message for [:rpc, :request, :failed_over]" do
      measurements = %{}

      meta = %{
        node_id: :some_node_id
      }

      assert capture_log(fn ->
               :telemetry.execute([:rpc, :request, :failed_over], measurements, meta)
             end) =~ "[error] some_node_id: Retrying the request"
    end

    test "logs an info message for [:event_listener, :new_head, :subscribe_success]" do
      :ok = Logger.configure(level: :info)
      measurements = %{}

      meta = %{
        node_id: :some_node_id
      }

      assert capture_log(fn ->
               :telemetry.execute(
                 [:event_listener, :new_head, :subscribe_success],
                 measurements,
                 meta
               )
             end) =~ "[info] some_node_id: Listening for new heads started"
    end

    test "logs an error message for [:event_listener, :new_head, :subscribe_failed]" do
      measurements = %{}

      meta = %{
        node_id: :some_node_id,
        error: "some error"
      }

      assert capture_log(fn ->
               :telemetry.execute(
                 [:event_listener, :new_head, :subscribe_failed],
                 measurements,
                 meta
               )
             end) =~ "[error] some_node_id: Failed to listen to new heads"
    end

    test "logs a debug message for [:event_listener, :new_head, :head_received]" do
      :ok = Logger.configure(level: :debug)
      measurements = %{}

      meta = %{
        node_id: :some_node_id,
        block_number: 1234,
        block_hash: "0x1234"
      }

      assert capture_log(fn ->
               :telemetry.execute(
                 [:event_listener, :new_head, :head_received],
                 measurements,
                 meta
               )
             end) =~ "[debug] some_node_id: New head 1234: 0x1234"
    end
  end
end
