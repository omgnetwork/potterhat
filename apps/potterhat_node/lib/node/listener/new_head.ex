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

defmodule PotterhatNode.Listener.NewHead do
  @moduledoc """
  Listens for newHeads events.
  """
  use WebSockex
  import PotterhatNode.Listener.Helper

  @subscription_id 1

  #
  # Client API
  #

  @doc """
  Starts a GenServer that listens to newHead events.
  """
  @spec start_link(String.t(), Keyword.t()) :: {:ok, pid()} | {:error, term()}
  def start_link(url, opts) do
    name = String.to_atom("#{opts[:node_id]}_newheads")
    opts = Keyword.put(opts, :name, name)

    case WebSockex.start_link(url, __MODULE__, opts, opts) do
      {:ok, pid} ->
        _ = listen(pid)
        {:ok, pid}

      error ->
        error
    end
  end

  defp listen(pid) do
    payload = %{
      jsonrpc: "2.0",
      id: @subscription_id,
      method: "eth_subscribe",
      params: [
        "newHeads"
      ]
    }

    :ok = WebSockex.send_frame(pid, {:text, Jason.encode!(payload)})
  end

  #
  # Server API
  #

  @doc false
  @spec init(Keyword.t()) :: {:ok, map()}
  def init(opts) do
    state = %{
      node_id: opts[:node_id],
      node_label: opts[:node_label]
    }

    {:ok, state}
  end

  @doc false
  @impl true
  def handle_frame({_type, serialized}, state) do
    {:ok, data} = Jason.decode(serialized)
    state = do_handle_frame(data, state)
    {:ok, state}
  end

  #
  # Handle received websocket frames
  #

  # Successful subscription
  defp do_handle_frame(%{"result" => result}, state) when is_binary(result)  do
    meta = %{
      node_id: state[:node_id],
      node_label: state[:node_label]
    }

    _ = :telemetry.execute([:event_listener, :new_head, :subscribe_success], %{}, meta)
    state
  end

  # Failed subscription
  defp do_handle_frame(%{"error" => error}, state) do
    meta = %{
      node_id: state[:node_id],
      node_label: state[:node_label],
      error: error
    }

    _ = :telemetry.execute([:event_listener, :new_head, :subscribe_failed], %{}, meta)
    state
  end

  # New head received
  defp do_handle_frame(%{"params" => _} = data, state) do
    block_number =
      data["params"]["result"]["number"]
      |> String.slice(2..-1)
      |> Base.decode16!(case: :mixed)
      |> :binary.decode_unsigned()

    block_hash = data["params"]["result"]["hash"]

    meta = %{
      node_id: state[:node_id],
      node_label: state[:node_label],
      block_number: block_number,
      block_hash: block_hash,
    }

    _ = :telemetry.execute([:event_listener, :new_head, :head_received], %{}, meta)
    state
  end
end
