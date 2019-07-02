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
    [:node, :event_received, :log],
    [:node, :event_received, :new_head],
    [:node, :event_received, :new_pending_transaction],
    [:node, :event_received, :sync_status]
  ]

  def supported_events, do: @supported_events

  def handle_event([:node, :event_received, :log], measurements, metadata, _config) do
    _ = increment("potterhat.events.log.num_received", 1, tags: ["node_id:#{metadata.node_id}"])
  end

  def handle_event([:node, :event_received, :new_head], measurements, metadata, _config) do
    _ =
      increment("potterhat.events.new_head.num_received", 1, tags: ["node_id:#{metadata.node_id}"])

    _ =
      gauge("potterhat.events.new_head.latest_block_number", measurements.block_number,
        tags: ["node_id:#{metadata.node_id}"]
      )
  end

  def handle_event(
        [:node, :event_received, :new_pending_transaction],
        measurements,
        metadata,
        _config
      ) do
    _ =
      increment("potterhat.events.new_pending_transaction.num_received", 1,
        tags: ["node_id:#{metadata.node_id}"]
      )
  end

  def handle_event([:node, :event_received, :sync_status], measurements, metadata, _config) do
    _ =
      increment("potterhat.events.sync_status.num_received", 1,
        tags: ["node_id:#{metadata.node_id}"]
      )

    _ =
      gauge("potterhat.events.sync_status.current_block", measurements.current_block,
        tags: ["node_id:#{metadata.node_id}"]
      )

    _ =
      gauge("potterhat.events.sync_status.highest_block", measurements.highest_block,
        tags: ["node_id:#{metadata.node_id}"]
      )
  end
end
