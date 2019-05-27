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

defmodule Potterhat.Node.EventLogger do
  require Logger
  alias Potterhat.Node

  @behaviour Potterhat.Node.Subscriber

  ## New block listening

  @impl true
  def handle_event(emitter, {:new_heads, %{"result" => result}}) when is_binary(result) do
    Logger.info("#{Node.get_label(emitter)} (#{inspect emitter}): Listening for new heads started...")
    :ok
  end

  @impl true
  def handle_event(emitter, {:new_heads, %{"error" => _} = data}) do
    Logger.warn("#{Node.get_label(emitter)} (#{inspect emitter}): Failed to listen to new heads: #{inspect(data)}")
    :ok
  end

  @impl true
  def handle_event(emitter, {:new_heads, data}) do
    block_hash = data["params"]["result"]["hash"]

    block_number =
      data["params"]["result"]["number"]
      |> String.slice(2..-1)
      |> Base.decode16!(case: :mixed)
      |> :binary.decode_unsigned()

    Logger.debug("#{Node.get_label(emitter)} (#{inspect emitter}): New block #{inspect block_number}: #{block_hash}")

    :ok
  end

  ## Logs listening

  @impl true
  def handle_event(emitter, {:logs, %{"result" => result}}) when is_binary(result) do
    Logger.info("#{Node.get_label(emitter)} (#{inspect emitter}): Listening for logs started...")
    :ok
  end

  @impl true
  def handle_event(emitter, {:logs, %{"error" => _} = data}) do
    Logger.warn("#{Node.get_label(emitter)} (#{inspect emitter}): Failed to listen to logs: #{inspect(data)}")
    :ok
  end

  @impl true
  def handle_event(emitter, {:logs, %{"params" => _} = log}) do
    Logger.debug("#{Node.get_label(emitter)} (#{inspect emitter}): New log: #{inspect(log)}")
    :ok
  end

  @impl true
  def handle_event(emitter, {:logs, data}) do
    Logger.warn("#{Node.get_label(emitter)} (#{inspect emitter}): Unknown logs data: #{inspect(data)}")
    :ok
  end

  ## New pending transactions listening

  @impl true
  def handle_event(emitter, {:new_pending_tranasctions, %{"result" => result}}) when is_binary(result) do
    Logger.info("#{Node.get_label(emitter)} (#{inspect emitter}): Listening for new pending transactions started...")
    :ok
  end

  @impl true
  def handle_event(emitter, {:new_pending_tranasctions, %{"error" => _} = data}) do
    Logger.warn("#{Node.get_label(emitter)} (#{inspect emitter}): Failed to listen to new_pending_tranasctions: #{inspect(data)}")
    :ok
  end

  @impl true
  def handle_event(emitter, {:new_pending_tranasctions, %{"params" => _} = txn}) do
    Logger.warn("#{Node.get_label(emitter)} (#{inspect emitter}): New new_pending_tranasctions data: #{inspect(txn)}")
    :ok
  end

  @impl true
  def handle_event(emitter, {:new_pending_tranasctions, data}) do
    Logger.warn("#{Node.get_label(emitter)} (#{inspect emitter}): Unknown new_pending_tranasctions data: #{inspect(data)}")
    :ok
  end

  ## Sync status listening

  @impl true
  def handle_event(emitter, {:sync_status, %{"result" => result}}) when is_binary(result) do
    Logger.info("#{Node.get_label(emitter)} (#{inspect emitter}): Listening for sync status started...")
    :ok
  end

  @impl true
  def handle_event(emitter, {:sync_status, %{"error" => _} = data}) do
    Logger.warn("#{Node.get_label(emitter)} (#{inspect emitter}): Failed to listen to sync status: #{inspect(data)}")
    :ok
  end

  @impl true
  def handle_event(emitter, {:sync_status, %{"params" => %{"result" => false}}}) do
    Logger.debug("#{Node.get_label(emitter)} (#{inspect emitter}): Sync stopped.")
    :ok
  end

  @impl true
  def handle_event(emitter, {:sync_status, %{"params" => %{"result" => result}}}) do
    Logger.debug("#{Node.get_label(emitter)} (#{inspect emitter}): Sync started."
      <> " Starting block: #{result["status"]["StartingBlock"]},"
      <> " Current block: #{result["status"]["CurrentBlock"]},"
      <> " Highest block: #{result["status"]["HighestBlock"]},"
    )
    :ok
  end
end
