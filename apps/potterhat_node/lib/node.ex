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

  defmodule Response do
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
  def stop(opts) when is_list(opts) do
    opts
    |> Keyword.fetch!(:node_id)
    |> stop()
  end

  def stop(pid), do: GenServer.stop(pid, :normal, 5000)

  @spec get_label(Keyword.t() | pid()) :: String.t()
  def get_label(opts) when is_list(opts) do
    opts
    |> Keyword.fetch!(:node_id)
    |> get_label()
  end

  def get_label(pid), do: GenServer.call(pid, :get_label)

  @spec subscribe(pid(), Keyword.t()) :: :ok
  def subscribe(subscriber, opts) do
    node_id = Keyword.fetch!(opts, :node_id)
    GenServer.call(node_id, {:subscribe, subscriber})
  end

  @spec unsubscribe(pid(), Keyword.t()) :: :ok
  def unsubscribe(unsubscriber, opts) do
    node_id = Keyword.fetch!(opts, :node_id)
    GenServer.call(node_id, {:subscribe, unsubscriber})
  end

  @spec rpc_request(map(), map(), Keyword.t()) :: :ok
  def rpc_request(body_params, header_params, opts) do
    node_id = Keyword.fetch!(opts, :node_id)
    GenServer.call(node_id, {:rpc_request, body_params, header_params})
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
    subscribers = [subscriber | state.subscribers]

    {:reply, :ok, %{state | subscribers: subscribers}}
  end

  @impl true
  def handle_call({:unsubscribe, unsubscriber}, _from, state) do
    subscribers = List.delete(state.subscribers, unsubscriber)

    {:reply, :ok, %{state | subscribers: subscribers}}
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
    response = %Response{
      status_code: raw.status_code,
      headers: raw.headers,
      body: raw.body
    }

    {:reply, {:ok, response}, state}
  end

  ## New block listening

  @impl true
  def handle_cast({:new_heads, %{"result" => result}}, state) when is_binary(result) do
    Logger.info("#{state[:label]} (#{inspect self()}): Listening for new heads started...")
    {:noreply, state}
  end

  @impl true
  def handle_cast({:new_heads, data}, state) do
    block_hash = data["params"]["result"]["hash"]

    block_number =
      data["params"]["result"]["number"]
      |> String.slice(2..-1)
      |> Base.decode16!(case: :mixed)
      |> :binary.decode_unsigned()

    Logger.debug("#{state[:label]} (#{inspect self()}): New block #{inspect block_number}: #{block_hash}")

    {:noreply, state}
  end

  ## Logs listening

  @impl true
  def handle_cast({:logs, %{"result" => result}}, state) when is_binary(result) do
    Logger.info("#{state[:label]} (#{inspect self()}): Listening for logs started...")
    {:noreply, state}
  end

  @impl true
  def handle_cast({:logs, %{"error" => _} = data}, state) do
    Logger.warn("#{state[:label]} (#{inspect self()}): Failed to listen to logs...")
    Logger.warn("#{state[:label]} (#{inspect self()}): Error: #{inspect(data)}")

    {:noreply, state}
  end

  @impl true
  def handle_cast({:logs, %{"params" => _} = log}, state) do
    Logger.debug("#{state[:label]} (#{inspect self()}): New log: #{inspect(log)}")
    {:noreply, state}
  end

  @impl true
  def handle_cast({:logs, data}, state) do
    Logger.warn("#{state[:label]} (#{inspect self()}): Unknown logs data: #{inspect(data)}")
    {:noreply, state}
  end

  ## New pending transactions listening

  @impl true
  def handle_cast({:new_pending_tranasctions, %{"result" => result}}, state) when is_binary(result) do
    Logger.info("#{state[:label]} (#{inspect self()}): Listening for new pending transactions started...")
    {:noreply, state}
  end

  @impl true
  def handle_cast({:new_pending_tranasctions, _data}, state) do
    {:noreply, state}
  end

  ## Sync status listening

  @impl true
  def handle_cast({:sync_status, %{"result" => result}}, state) when is_binary(result) do
    Logger.info("#{state[:label]} (#{inspect self()}): Listening for sync status started...")
    {:noreply, state}
  end

  @impl true
  def handle_cast({:sync_status, %{"params" => %{"result" => false}}}, state) do
    Logger.debug("#{state[:label]} (#{inspect self()}): Sync stopped.")
    {:noreply, state}
  end

  @impl true
  def handle_cast({:sync_status, %{"params" => %{"result" => result}}}, state) do
    Logger.debug("#{state[:label]} (#{inspect self()}): Sync started."
      <> " Starting block: #{result["status"]["StartingBlock"]},"
      <> " Current block: #{result["status"]["CurrentBlock"]},"
      <> " Highest block: #{result["status"]["HighestBlock"]},"
    )
    {:noreply, state}
  end
end
