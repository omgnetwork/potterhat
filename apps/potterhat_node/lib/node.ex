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

defmodule Potterhat.Node do
  @moduledoc """
  Documentation for Potterhat.Node.
  """
  use GenServer
  require Logger
  alias Potterhat.Node.Subscription.{Log, NewHead, NewPendingTransaction, SyncStatus}

  defmodule RPCResponse do
    @type t() :: %__MODULE__{
      status_code: non_neg_integer(),
      headers: Keyword.t(),
      body: String.t()
    }
    defstruct status_code: nil, headers: nil, body: nil
  end

  #
  # Client API
  #

  @spec start_link(Keyword.t()) :: GenServer.on_start()
  def start_link(opts) do
    id = Map.fetch!(opts, :id)
    GenServer.start_link(__MODULE__, opts, name: id)
  end

  @spec stop(Keyword.t() | pid()) :: :ok
  def stop(server) do
    GenServer.stop(server, :normal, 5000)
  end

  @spec get_label(Keyword.t() | pid()) :: String.t()
  def get_label(server) do
    GenServer.call(server, :get_label)
  end

  @spec get_priority(pid()) :: integer()
  def get_priority(server) do
    GenServer.call(server, :get_priority)
  end

  @spec subscribe(pid(), pid()) :: :ok
  def subscribe(server, subscriber) do
    GenServer.call(server, {:subscribe, subscriber})
  end

  @spec unsubscribe(pid(), pid()) :: :ok
  def unsubscribe(server, unsubscriber) do
    GenServer.call(server, {:unsubscribe, unsubscriber})
  end

  @spec get_subscribers(pid()) :: [pid()]
  def get_subscribers(server) do
    GenServer.call(server, :get_subscribers)
  end

  @spec rpc_request(pid(), map(), map()) :: {:ok, %RPCResponse{}} | {:error, any()}
  def rpc_request(server, body_params, header_params) do
    GenServer.call(server, {:rpc_request, body_params, header_params})
  catch
    :exit, value -> {:error, value}
  end

  #
  # Server API
  #

  @impl true
  def init(opts) do
    Process.flag(:trap_exit, true)

    state = %{
      id: Map.fetch!(opts, :id),
      label: Map.fetch!(opts, :label),
      rpc: Map.fetch!(opts, :rpc),
      ws: Map.fetch!(opts, :ws),
      priority: Map.fetch!(opts, :priority),
      state: :starting,
      node_registry: Map.get(opts, :node_registry),
      listening_events: [],
      subscribers: []
    }

    {:ok, state, {:continue, :print_version}}
  end

  @impl true
  def handle_info({:EXIT, _child_pid, reason}, state) do
    {:stop, reason, state}
  end

  @impl true
  def terminate(reason, state) do
    _ = Logger.info("#{state.label} (#{inspect self()}: Terminating because #{inspect(reason)}")

    _ =
      case state.node_registry do
        nil -> :noop
        registry -> registry.deregister(self())
      end

    reason
  end

  @impl true
  def handle_continue(:print_version, state) do
    case Ethereumex.HttpClient.web3_client_version(url: state[:rpc]) do
      {:ok, version} ->
        _ = Logger.info("#{state.label} (#{inspect self()}): Connected: #{version}")
        {:noreply, %{state | state: :started}, {:continue, :register_with_manager}}

      {:error, error} ->
        retry_period_ms = Application.get_env(:potterhat_node, :retry_period_ms)
        _ = Logger.warn("#{state.label} (#{inspect self()}): Failed to connect: #{error}. Retrying in #{retry_period_ms} ms.")
        Process.sleep(retry_period_ms)
        {:noreply, %{state | state: :started}, {:continue, :print_version}}
    end
  end

  @impl true
  def handle_continue(:register_with_manager, state) do
    _ =
      case state.node_registry do
        nil -> :noop
        registry -> registry.register(self(), state.priority)
      end

    {:noreply, state, {:continue, :subscribe_events}}
  end

  @impl true
  def handle_continue(:subscribe_events, state) do
    opts = [
      node_id: state[:id],
      label: state[:label],
      listener: self()
    ]

    listening_events =
      :potterhat_node
      |> Application.get_env(:listen_events)
      |> Enum.reduce([], fn
        :sync_status, events ->
          SyncStatus.start_link(state[:ws], opts)
          [:sync_status | events]

        :new_head, events ->
          NewHead.start_link(state[:ws], opts)
          [:new_head | events]

        :new_pending_transaction, events ->
          NewPendingTransaction.start_link(state[:ws], opts)
          [:new_pending_transaction | events]

        :log, events ->
          Log.start_link(state[:ws], opts)
          [:log | events]

        _, events ->
          events
      end)

    {:noreply, %{state | state: :listening, listening_events: listening_events}}
  end

  @impl true
  def handle_call(:get_priority, _from, state) do
    {:reply, state.priority, state}
  end

  @impl true
  def handle_call(:get_label, _from, state) do
    {:reply, state.label, state}
  end

  @impl true
  def handle_call({:subscribe, subscriber}, _from, state) do
    {response, new_state} =
      state.subscribers
      |> Enum.member?(subscriber)
      |> case do
        false ->
          subscribed = [subscriber | state.subscribers]
          {:ok, %{state | subscribers: subscribed}}

        true ->
          {{:error, :already_subscribed}, state}
      end

    {:reply, response, new_state}
  end

  @impl true
  def handle_call({:unsubscribe, unsubscriber}, _from, state) do
    {response, new_state} =
      state.subscribers
      |> Enum.member?(unsubscriber)
      |> case do
        true ->
          unsubscribed = List.delete(state.subscribers, unsubscriber)
          {:ok, %{state | subscribers: unsubscribed}}

        false ->
          {{:error, :not_subscribed}, state}
      end

    {:reply, response, new_state}
  end

  @impl true
  def handle_call(:get_subscribers, _from, state) do
    {:reply, state.subscribers, state}
  end

  @impl true
  def handle_call({:rpc_request, body_params, header_params}, _from, state) do
    encoded_params = Jason.encode!(body_params)

    # Send only supported headers. Infura doesn't like extra headers.
    header_params = Enum.filter(header_params, fn
      {"content-type", _} -> true
      _ -> false
    end)

    _ = HTTPoison.start()
    raw = HTTPoison.post!(state[:rpc], encoded_params, header_params)

    # This encapsulates 3rd party struct into our own.
    response = %RPCResponse{
      status_code: raw.status_code,
      headers: raw.headers,
      body: raw.body
    }

    {:reply, {:ok, response}, state}
  end

  def handle_cast({:event_received, event, message}, state) do
    Enum.each(state.subscribers, fn subscriber ->
      subscriber.handle_event(self(), {event, message})
    end)

    {:noreply, state}
  end
end
