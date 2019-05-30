  defmodule PotterhatNode.MockListener do
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
