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

defmodule PotterhatUtils.TelemetrySubscriber do
  @moduledoc """
  A behaviour for those looking to subscribe to telemetry events easily.
  """

  @callback init() :: :ok
  @callback supported_events() :: [:telemetry.event_name()]
  @callback handle_event(
              :telemetry.event_name(),
              :telemetry.event_measurements(),
              :telemetry.event_metadata(),
              :telemetry.handler_config()
            ) :: any()

  def attach(id, subscriber) do
    :ok = subscriber.init()

    :telemetry.attach_many(
      id,
      subscriber.supported_events(),
      &subscriber.handle_event/4,
      nil
    )
  end

  def attach_from_config(app) do
    app
    |> Application.get_env(:telemetry_subscribers, %{})
    |> Enum.each(fn {id, subscriber} ->
      :ok = attach(id, subscriber)
    end)
  end
end
