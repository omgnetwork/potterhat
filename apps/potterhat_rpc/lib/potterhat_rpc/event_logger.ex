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

defmodule PotterhatRPC.EventLogger do
  @moduledoc """
  Logs telemetry events emitted by PotterhatRPC.
  """
  import PotterhatUtils.BaseLogger

  @behaviour PotterhatUtils.TelemetrySubscriber

  @supported_events [
    [:rpc, :server, :starting],
    [:rpc, :request, :failed_over]
  ]

  @impl true
  def init, do: :ok

  @impl true
  def supported_events, do: @supported_events

  #
  # RPC requests
  #

  @impl true
  def handle_event([:rpc, :server, :starting], _measurements, meta, _config) do
    info("Starting RPC server on port #{meta.port}", meta)
  end

  @impl true
  def handle_event([:rpc, :request, :failed_over], _measurements, meta, _config) do
    error("Retrying the request with the next available node.", meta)
  end
end
