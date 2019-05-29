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

defmodule Potterhat.Node.EventLoggerTest do
  use ExUnit.Case, async: true
  import ExUnit.CaptureLog
  alias Potterhat.Node.EventLogger
  require Logger

  setup do
    # Temporarily allows verbose logging so event logging can be tests.
    original_level = Application.get_env(:logger, :level)
    :ok = Logger.configure(level: :debug)
    on_exit(fn -> Logger.configure(level: original_level) end)

    meta =
      %{
        opts: [
          label: "The Node",
          pid: self()
        ]
      }

    {:ok, meta}
  end

  describe "log_event/2 with new heads events" do
    test "logs when listening started", meta do
      data = %{"result" => "some result"}

      log =
        capture_log(fn ->
          EventLogger.log_event({:new_heads, data}, meta.opts)
        end)

      assert Regex.match?(~r/.+The Node \(#PID<.+>\): Listening for new heads started.+/, log)
    end

    test "logs when listening failed", meta do
      data = %{"error" => "some error"}

      log =
        capture_log(fn ->
          EventLogger.log_event({:new_heads, data}, meta.opts)
        end)

      assert Regex.match?(~r/.+The Node \(#PID<.+>\): Failed to listen to new heads: .+"some error".+/, log)
    end

    test "logs when a new head is received", meta do
      data = %{"params" => %{"result" => %{"number" => "0x77be11", "hash" => "0x1234"}}}

      log =
        capture_log(fn ->
          EventLogger.log_event({:new_heads, data}, meta.opts)
        end)

      assert Regex.match?(~r/.+The Node \(#PID<.+>\): New block 7847441: 0x1234/, log)
    end
  end

  describe "log_event/2 with logs events" do
    test "logs when listening started", meta do
      data = %{"result" => "some result"}

      log =
        capture_log(fn ->
          EventLogger.log_event({:logs, data}, meta.opts)
        end)

      assert Regex.match?(~r/.+The Node \(#PID<.+>\): Listening for logs started.+/, log)
    end

    test "logs when listening failed", meta do
      data = %{"error" => "some error"}

      log =
        capture_log(fn ->
          EventLogger.log_event({:logs, data}, meta.opts)
        end)

      assert Regex.match?(~r/.+The Node \(#PID<.+>\): Failed to listen to logs: .+"some error".+/, log)
    end

    test "logs when a new log is received", meta do
      data = %{"params" => "some data"}

      log =
        capture_log(fn ->
          EventLogger.log_event({:logs, data}, meta.opts)
        end)

      assert Regex.match?(~r/.+The Node \(#PID<.+>\): New log: .+ "some data"/, log)
    end

    test "logs when an unknown log is received", meta do
      data = "unknown data"

      log =
        capture_log(fn ->
          EventLogger.log_event({:logs, data}, meta.opts)
        end)

      assert Regex.match?(~r/.+The Node \(#PID<.+>\): Unknown logs data: "unknown data"/, log)
    end
  end

  describe "log_event/2 with new_pending_transactions" do
    test "logs when listening started", meta do
      data = %{"result" => "some result"}

      log =
        capture_log(fn ->
          EventLogger.log_event({:new_pending_transactions, data}, meta.opts)
        end)

      assert Regex.match?(~r/.+The Node \(#PID<.+>\): Listening for new_pending_transactions started.+/, log)
    end

    test "logs when listening failed", meta do
      data = %{"error" => "some error"}

      log =
        capture_log(fn ->
          EventLogger.log_event({:new_pending_transactions, data}, meta.opts)
        end)

      assert Regex.match?(~r/.+The Node \(#PID<.+>\): Failed to listen to new_pending_transactions: .+"some error".+/, log)
    end

    test "logs when a new pending transactions is received", meta do
      data = %{"params" => "some data"}

      log =
        capture_log(fn ->
          EventLogger.log_event({:new_pending_transactions, data}, meta.opts)
        end)

      assert Regex.match?(~r/.+The Node \(#PID<.+>\): New new_pending_transactions data: .+ "some data"/, log)
    end

    test "logs when an unknown pending transactions is received", meta do
      data = "unknown data"

      log =
        capture_log(fn ->
          EventLogger.log_event({:new_pending_transactions, data}, meta.opts)
        end)

      assert Regex.match?(~r/.+The Node \(#PID<.+>\): Unknown new_pending_transactions data: "unknown data"/, log)
    end
  end

  describe "log_event/2 with sync_status" do
    test "logs when listening started", meta do
      data = %{"result" => "some result"}

      log =
        capture_log(fn ->
          EventLogger.log_event({:sync_status, data}, meta.opts)
        end)

      assert Regex.match?(~r/.+The Node \(#PID<.+>\): Listening for sync status started.+/, log)
    end

    test "logs when listening failed", meta do
      data = %{"error" => "some error"}

      log =
        capture_log(fn ->
          EventLogger.log_event({:sync_status, data}, meta.opts)
        end)

      assert Regex.match?(~r/.+The Node \(#PID<.+>\): Failed to listen to sync status: .+"some error".+/, log)
    end

    test "logs when a sync starts", meta do
      data = %{
        "params" => %{
          "subscription" => "0xe2ffeb2703bcf602d42922385829ce96",
          "result" => %{
            "syncing" => true,
            "status" => %{
              "StartingBlock" => 674427,
              "CurrentBlock" => 67400,
              "HighestBlock" => 674432,
              "PulledStates" => 0,
              "KnownStates" => 0
            }
          }
        }
      }

      log =
        capture_log(fn ->
          EventLogger.log_event({:sync_status, data}, meta.opts)
        end)

      assert Regex.match?(~r/.+The Node \(#PID<.+>\): Sync started.+/, log)
    end

    test "logs when a sync stops", meta do
      data = %{
        "params" => %{
          "result" => false
        }
      }

      log =
        capture_log(fn ->
          EventLogger.log_event({:sync_status, data}, meta.opts)
        end)

      assert Regex.match?(~r/.+The Node \(#PID<.+>\): Sync stopped.+/, log)
    end
  end
end
