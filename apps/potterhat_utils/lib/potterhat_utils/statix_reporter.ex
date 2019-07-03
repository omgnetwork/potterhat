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

defmodule PotterhatUtils.StatixReporter do
  @moduledoc """
  Reports events to Statix backend.
  """
  use Statix, runtime_config: true

  @supported_events [
    [:active_nodes, :registered],
    [:active_nodes, :deregistered],
    [:rpc, :request, :start],
    [:rpc, :request, :stop],
    [:rpc, :request, :success],
    [:rpc, :request, :failed],
    [:rpc, :request, :failed_over],
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

  def supported_events, do: @supported_events

  #
  # Active nodes
  #

  def handle_event([:active_nodes, :registered], measurements, meta, _config) do
    _ = increment("potterhat.active_nodes.num_registered", 1, opts(meta))
    _ = gauge("potterhat.active_nodes.total_active", measurements.num_active, opts(meta))
  end

  def handle_event([:active_nodes, :deregistered], measurements, meta, _config) do
    _ = increment("potterhat.active_nodes.num_deregistered", 1, opts(meta))
    _ = gauge("potterhat.active_nodes.total_active", measurements.num_active, opts(meta))
  end

  #
  # RPC requests
  #

  def handle_event([:rpc, :request, :start], _measurements, meta, _config) do
    eth_method = meta.conn.assigns[:eth_method]
    _ = increment("potterhat.rpc.num_requests", 1, opts(meta, tags: ["eth_method:#{eth_method}"]))
  end

  def handle_event([:rpc, :request, :stop], measurements, meta, _config) do
    eth_method = meta.conn.assigns[:eth_method]
    _ = timing("potterhat.rpc.response_time", measurements.duration, opts(meta, tags: ["eth_method:#{eth_method}"]))
  end

  def handle_event([:rpc, :request, :success], _measurements, meta, _config) do
    eth_method = meta.conn.assigns[:eth_method]
    _ = increment("potterhat.rpc.num_success", 1, opts(meta, tags: ["eth_method:#{eth_method}"]))
  end

  def handle_event([:rpc, :request, :failed], measurements, meta, _config) do
    eth_method = meta.conn.assigns[:eth_method]
    _ = increment("potterhat.rpc.num_failed", 1, opts(meta, tags: ["eth_method:#{eth_method}"]))
  end

  def handle_event([:rpc, :request, :failed_over], _measurements, meta, _config) do
    eth_method = meta.body_params["method"]
    _ = increment("potterhat.rpc.num_failed_over", 1, opts(meta, tags: ["eth_method:#{eth_method}"]))
  end

  #
  # New head events
  #

  def handle_event([:event_listener, :new_head, :subscribe_success], _measurements, meta, _config) do
    _ = increment("potterhat.events.new_head.num_subscribe_success", 1, opts(meta))
  end

  def handle_event([:event_listener, :new_head, :subscribe_failed], _measurements, meta, _config) do
    _ = increment("potterhat.events.new_head.num_subscribe_failed", 1, opts(meta))
  end

  def handle_event([:event_listener, :new_head, :head_received], _measurements, meta, _config) do
    _ = increment("potterhat.events.new_head.num_received", 1, opts(meta))
    _ = gauge("potterhat.events.new_head.block_number_received", meta.block_number, opts(meta))
  end

  #
  # Log events
  #

  def handle_event([:event_listener, :log, :subscribe_success], _measurements, meta, _config) do
    _ = increment("potterhat.events.log.num_subscribe_success", 1, opts(meta))
  end

  def handle_event([:event_listener, :log, :subscribe_failed], _measurements, meta, _config) do
    _ = increment("potterhat.events.log.num_subscribe_failed", 1, opts(meta))
  end

  def handle_event([:event_listener, :log, :log_received], _measurements, meta, _config) do
    _ = increment("potterhat.events.log.num_received", 1, opts(meta))
  end

  #
  # New pending transaction events
  #

  def handle_event([:event_listener, :new_pending_transaction, :subscribe_success], _measurements, meta, _config) do
    _ = increment("potterhat.events.new_pending_transaction.num_subscribe_success", 1, opts(meta))
  end

  def handle_event([:event_listener, :new_pending_transaction, :subscribe_failed], _measurements, meta, _config) do
    _ = increment("potterhat.events.new_pending_transaction.num_subscribe_failed", 1, opts(meta))
  end

  def handle_event([:event_listener, :new_pending_transaction, :transaction_received], _measurements, meta, _config) do
    _ = increment("potterhat.events.new_pending_transaction.num_received", 1, opts(meta))
  end

  #
  # Sync status events
  #

  def handle_event([:event_listener, :sync_status, :subscribe_success], _measurements, meta, _config) do
    _ = increment("potterhat.events.sync_status.num_subscribe_success", 1, opts(meta))
  end

  def handle_event([:event_listener, :sync_status, :subscribe_failed], _measurements, meta, _config) do
    _ = increment("potterhat.events.sync_status.num_subscribe_failed", 1, opts(meta))
  end

  def handle_event([:event_listener, :sync_status, :sync_started], _measurements, meta, _config) do
    _ = increment("potterhat.events.sync_status.num_sync_started", 1, opts(meta))
    _ = increment("potterhat.events.sync_status.num_received", 1, opts(meta))
  end

  def handle_event([:event_listener, :sync_status, :sync_stopped], measurements, meta, _config) do
    _ = increment("potterhat.events.sync_status.num_sync_stopped", 1, opts(meta))
    _ = increment("potterhat.events.sync_status.num_received", 1, opts(meta))
    _ = gauge("potterhat.events.sync_status.current_block", measurements.current_block, opts(meta))
    _ = gauge("potterhat.events.sync_status.highest_block", measurements.highest_block, opts(meta))
  end

  #
  # Generate Statix options
  #

  defp opts(meta, opts \\ [])

  # Add a node_id tag if node_id is present in the metadata
  defp opts(%{node_id: node_id}, opts) do
    node_tag = "node_id:#{node_id}"

    Keyword.update(opts, :tags, [node_tag], fn tags ->
      [node_tag | tags]
    end)
  end

  defp opts(_meta, opts), do: opts
end
