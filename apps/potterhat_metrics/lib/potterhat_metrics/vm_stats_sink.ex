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

defmodule PotterhatMetrics.VmStatsSink do
  @moduledoc """
  Collects VM stats and report to Statix.
  """
  alias PotterhatMetrics.StatixReporter

  @behaviour :vmstats_sink

  @impl :vmstats_sink
  def collect(:counter, key, value) do
    StatixReporter.set(key, value)
  end

  @impl :vmstats_sink
  def collect(:gauge, key, value) do
    StatixReporter.gauge(key, value)
  end

  @impl :vmstats_sink
  def collect(:timing, key, value) do
    StatixReporter.timing(key, value)
  end
end
