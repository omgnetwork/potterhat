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

defmodule PotterhatUtils.TelemetrySubscriberTest do
  use ExUnit.Case, async: true
  alias PotterhatUtils.TelemetrySubscriber

  @event [:some, :event]

  defmodule MockSubscriber do
    @behaviour PotterhatUtils.TelemetrySubscriber
    @event [:some, :event]

    @impl true
    def init, do: :ok

    @impl true
    def supported_events, do: [@event]

    @impl true
    def handle_event(_, _, _, _), do: :noop
  end

  describe "attach/2" do
    test "attaches the subscriber to telemetry" do
      handler_id = "test_attach_#{:rand.uniform(999)}"

      # Make sure the handler isn't already there
      handlers = :telemetry.list_handlers(@event)
      refute Enum.any?(handlers, fn h -> h.id == handler_id end)

      :ok = TelemetrySubscriber.attach(handler_id, MockSubscriber)

      # Assert that the handler is added
      handlers = :telemetry.list_handlers(@event)
      assert Enum.any?(handlers, fn h -> h.id == handler_id end)
    end
  end

  describe "attach_from_config/1" do
    handler_id = "test_attach_from_config_#{:rand.uniform(999)}"

    # Create a mock application config so our target can retrieve from it
    app = String.to_atom("app_#{handler_id}")
    :ok = Application.put_env(app, :telemetry_subscribers, %{handler_id => MockSubscriber})

    # Make sure the handler isn't already there
    handlers = :telemetry.list_handlers(@event)
    refute Enum.any?(handlers, fn h -> h.id == handler_id end)

    :ok = TelemetrySubscriber.attach_from_config(app)

    # Assert that the handler is added
    handlers = :telemetry.list_handlers(@event)
    assert Enum.any?(handlers, fn h -> h.id == handler_id end)
  end
end
