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

defmodule PotterhatRPC.EventLoggerTest do
  # Async false due to changing log level
  use ExUnit.Case, async: false
  import ExUnit.CaptureLog
  alias PotterhatRPC.EventLogger

  setup do
    handler_id = "test_rpc_event_logger_#{:rand.uniform(999_999)}"

    :ok = :telemetry.attach_many(
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
      :ok = Enum.each(EventLogger.supported_events(), fn event ->
        assert is_list(event)
        assert Enum.all?(event, fn item -> is_atom(item) end)
      end)
    end
  end

  describe "handle_event/4" do
    test "logs an info message for [:rpc, :server, :starting]" do
      :ok = Logger.configure(level: :info)

      meta = %{
        node_id: :some_node_id,
        port: 1234
      }

      assert capture_log(fn ->
        :telemetry.execute([:rpc, :server, :starting], %{}, meta)
      end) =~ "[info] some_node_id: Starting RPC server"
    end

    test "logs an error message for [:rpc, :request, :failed_over]" do
      meta = %{
        node_id: :some_node_id,
        body_params: %{"method" => "ethMethod"}
      }

      assert capture_log(fn ->
        :telemetry.execute([:rpc, :request, :failed_over], %{}, meta)
      end) =~ "[error] some_node_id: Retrying the request"
    end
  end
end
