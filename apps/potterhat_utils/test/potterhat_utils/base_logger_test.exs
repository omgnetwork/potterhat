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

defmodule PotterhatUtils.BaseLoggerTest do
  # Async false due to changing log level
  use ExUnit.Case, async: false
  import ExUnit.CaptureLog
  alias PotterhatUtils.BaseLogger
  require Logger

  setup do
    meta = %{
      message: "Some log message",
      log_meta: %{node_id: :some_node_id}
    }

    log_level = Logger.level()
    on_exit(fn -> Logger.configure(level: log_level) end)

    {:ok, meta}
  end

  describe "debug/2" do
    test "logs a debug message with node_id prefixed", meta do
      :ok = Logger.configure(level: :debug)

      log = capture_log(fn ->
        BaseLogger.debug(meta.message, meta.log_meta)
      end)

      assert log =~ "[debug] some_node_id: Some log message"
    end
  end

  describe "info/2" do
    test "logs an info message with node_id prefixed", meta do
      :ok = Logger.configure(level: :info)

      log = capture_log(fn ->
        BaseLogger.info(meta.message, meta.log_meta)
      end)

      assert log =~ "[info] some_node_id: Some log message"
    end
  end

  describe "warn/2" do
    test "logs a warn message with node_id prefixed", meta do
      log = capture_log(fn ->
        BaseLogger.warn(meta.message, meta.log_meta)
      end)

      assert log =~ "[warn] some_node_id: Some log message"
    end
  end

  describe "error/2" do
    test "logs an error message with node_id prefixed", meta do
      log = capture_log(fn ->
        BaseLogger.error(meta.message, meta.log_meta)
      end)

      assert log =~ "[error] some_node_id: Some log message"
    end
  end
end
