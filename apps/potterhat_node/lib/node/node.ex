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

defmodule PotterhatNode.Node do
  @moduledoc """
  A GenServer that listens to an Ethereum Node.
  """
  use GenServer
  require Logger
  alias PotterhatNode.{ActiveNodes, EventLogger}
  alias PotterhatNode.Listener.NewHead

  defmodule RPCResponse do
    @moduledoc """
    The struct for the response returned from an RPC call.
    """

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

  @spec start_link(map()) :: GenServer.on_start()
  def start_link(opts) do
    id = Map.fetch!(opts, :id)
    GenServer.start_link(__MODULE__, opts, name: id)
  end

  @spec get_label(pid()) :: String.t()
  def get_label(server) do
    GenServer.call(server, :get_label)
  end

  @spec get_priority(pid()) :: integer()
  def get_priority(server) do
    GenServer.call(server, :get_priority)
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
      event_listener: nil,
      node_registry: Map.get(opts, :node_registry)
    }

    {:ok, state, {:continue, :listen}}
  end

  @impl true
  def handle_continue(:listen, state) do
    opts = [
      node_id: state[:id],
      label: state[:label]
    ]

    case NewHead.start_link(state[:ws], opts) do
      {:ok, pid} ->
        _ = Logger.info("#{state.label} (#{inspect(self())}): Connected.")

        {:noreply, %{state | state: :registering, event_listener: pid},
         {:continue, :register_with_manager}}

      {:error, error} ->
        retry_period_ms = Application.get_env(:potterhat_node, :retry_period_ms)

        _ =
          Logger.warn(
            "#{state.label} (#{inspect(self())}): Failed to connect: #{inspect(error)}. Retrying in #{
              retry_period_ms
            } ms."
          )

        :ok = Process.sleep(retry_period_ms)
        {:noreply, %{state | state: :restarting}, {:continue, :listen}}
    end
  end

  @impl true
  def handle_continue(:register_with_manager, state) do
    _ =
      case state.node_registry do
        nil -> :noop
        registry -> ActiveNodes.register(registry, self(), state.priority)
      end

    {:noreply, %{state | state: :started}}
  end

  # Handles termination of the event listener
  @impl true
  def handle_info({:EXIT, pid, reason}, %{event_listener_listener: pid} = state) do
    _ =
      Logger.info(
        "#{state.label} (#{inspect(self())}: Event listener terminated with reason: #{
          inspect(reason)
        }"
      )

    _ =
      case state.node_registry do
        nil -> :noop
        registry -> ActiveNodes.deregister(registry, self())
      end

    {:noreply, %{state | state: :restarting}, {:continue, :listen}}
  end

  # Ignore any other dying child if it is not the listener
  @impl true
  def handle_info({:EXIT, _, _}, state) do
    {:noreply, state}
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
  def handle_call({:rpc_request, body_params, header_params}, _from, state) do
    encoded_params = Jason.encode!(body_params)

    # Send only supported headers. Infura doesn't like extra headers.
    header_params =
      Enum.filter(header_params, fn
        {"content-type", _} -> true
        _ -> false
      end)

    case HTTPoison.post(state[:rpc], encoded_params, header_params) do
      {:ok, raw} ->
        # This encapsulates 3rd party struct into our own.
        response = %RPCResponse{
          status_code: raw.status_code,
          headers: raw.headers,
          body: raw.body
        }

        {:reply, {:ok, response}, state}

      {:error, _} = error ->
        {:reply, error, state}
    end
  end

  @impl true
  def handle_cast({:event_received, event, message}, state) do
    _ = EventLogger.log_event({event, message}, label: state.label, pid: self())

    {:noreply, state}
  end
end
