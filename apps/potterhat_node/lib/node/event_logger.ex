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

defmodule PotterhatNode.EventLogger do
  @moduledoc """
  Logs telemetry events emitted by PotterhatNode.
  """
  import PotterhatUtils.BaseLogger

  @behaviour PotterhatUtils.TelemetrySubscriber

  @supported_events [
    [:active_nodes, :registered],
    [:active_nodes, :deregistered],
    [:event_listener, :new_head, :subscribe_success],
    [:event_listener, :new_head, :subscribe_failed],
    [:event_listener, :new_head, :head_received],
    [:event_listener, :log, :subscribe_success],
    [:event_listener, :log, :subscribe_failed],
    [:event_listener, :log, :log_received],
    [:event_listener, :new_pending_transaction, :subscribe_success],
    [:event_listener, :new_pending_transaction, :subscribe_failed],
    [:event_listener, :new_pending_transaction, :transaction_received],
    [:event_listener, :sync_status, :subscribe_success],
    [:event_listener, :sync_status, :subscribe_failed],
    [:event_listener, :sync_status, :sync_started],
    [:event_listener, :sync_status, :sync_stopped]
  ]

  @impl true
  def init, do: :ok

  @impl true
  def supported_events, do: @supported_events

  #
  # Active nodes
  #

  @impl true
  def handle_event([:active_nodes, :registered], measurements, meta, _config) do
    debug("Registered node: #{inspect(meta.pid)}. Active nodes: #{measurements.num_active}.", meta)
  end

  @impl true
  def handle_event([:active_nodes, :deregistered], measurements, meta, _config) do
    debug("Deregistered node: #{inspect(meta.pid)}. Active nodes: #{measurements.num_active}.", meta)
  end

  #
  # RPC requests
  #

  @impl true
  def handle_event([:rpc, :request, :failed_over], _measurements, meta, _config) do
    error("Retrying the request with the next available node.", meta)
  end

  #
  # New head events
  #

  @impl true
  def handle_event([:event_listener, :new_head, :subscribe_success], _measurements, meta, _config) do
    info("Listening for new heads started...", meta)
  end

  @impl true
  def handle_event([:event_listener, :new_head, :subscribe_failed], _measurements, meta, _config) do
    error("Failed to listen to new heads: #{inspect(meta.error)}", meta)
  end

  @impl true
  def handle_event([:event_listener, :new_head, :head_received], _measurements, meta, _config) do
    debug("New head #{meta.block_number}: #{meta.block_hash}", meta)
  end

  @impl true
  def handle_event([:event_listener, :new_head, :subscribe_success], _measurements, meta, _config) do
    info("Listening for new heads started...", meta)
  end

  #
  # Log events
  #

  @impl true
  def handle_event([:event_listener, :log, :subscribe_success], _measurements, meta, _config) do
    info("Listening for logs started...", meta)
  end

  @impl true
  def handle_event([:event_listener, :log, :subscribe_failed], _measurements, meta, _config) do
    error("Failed to listen to logs: #{inspect(meta.error)}", meta)
  end

  @impl true
  def handle_event([:event_listener, :log, :log_received], measurements, meta, _config) do
    debug("New log: block #{meta.block_number}, index #{meta.log_index}", meta)
  end

  #
  # New pending transaction events
  #

  @impl true
  def handle_event([:event_listener, :new_pending_transaction, :subscribe_success], _measurements, meta, _config) do
    info("Listening for new pending transactions started...", meta)
  end

  @impl true
  def handle_event([:event_listener, :new_pending_transaction, :subscribe_failed], _measurements, meta, _config) do
    error("Failed to listen to new pending transactions: #{inspect(meta.error)}", meta)
  end

  @impl true
  def handle_event([:event_listener, :new_pending_transaction, :transaction_received], measurements, meta, _config) do
    debug("New pending transaction: #{meta.transaction_hash}", meta)
  end

  #
  # Sync status events
  #

  @impl true
  def handle_event([:event_listener, :sync_status, :subscribe_success], _measurements, meta, _config) do
    info("Listening for sync status started...", meta)
  end

  @impl true
  def handle_event([:event_listener, :sync_status, :subscribe_failed], _measurements, meta, _config) do
    error("Failed to listen to sync status: #{inspect(meta.error)}", meta)
  end

  @impl true
  def handle_event([:event_listener, :sync_status, :sync_started], measurements, meta, _config) do
    message = """
    Sync started.
      - Starting block: #{measurements.starting_block}"
      - Current block: #{measurements.current_block}"
      - Highest block: #{measurements.highest_block}"
    """

    debug(message, meta)
  end

  @impl true
  def handle_event([:event_listener, :sync_status, :sync_stopped], _measurements, meta, _config) do
    debug("Sync stopped.", meta)
  end
end
