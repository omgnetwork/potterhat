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

  defmodule PotterhatNode.MockNode do
    use GenServer

    #
    # Client API
    #

    def get_events(pid) do
      GenServer.call(pid, :get_events)
    end

    #
    # Server callbacks
    #

    def init(_opts) do
      {:ok, %{
        received_events: []
      }}
    end

    def handle_cast({:event_received, _type, _data} = event, state) do
      events = [event | state.received_events]
      {:noreply, %{state | received_events: events}}
    end

    def handle_call(:get_events, _from, state) do
      {:reply, state.received_events, state}
    end

    def handle_call(request, _from, state) do
      called = [request | state.called]
      {:reply, :ok, %{state | called: called}}
    end
  end
