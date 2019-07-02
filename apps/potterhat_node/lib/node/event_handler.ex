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

defmodule PotterhatNode.EventHandler do
  @moduledoc """
  Handle application events, mainly for logging and emitting metrics.

  Any event that is expected to be logged or sent as metrics should go through
  this module. This allows us to separate the actual business logic code from
  logging and metrics code, and avoids changes to the logging or metrics impacting
  the business logic.
  """
  require Logger

  ## New block listening

  def handle({:new_head, %{"result" => result}}, opts) when is_binary(result) do
    info("Listening for new heads started...", opts)
  end

  def handle({:new_head, %{"error" => _} = data}, opts) do
    error("Failed to listen to new heads: #{inspect(data)}", opts)
  end

  def handle({:new_head, data}, opts) do
    block_hash = data["params"]["result"]["hash"]

    block_number =
      data["params"]["result"]["number"]
      |> String.slice(2..-1)
      |> Base.decode16!(case: :mixed)
      |> :binary.decode_unsigned()

    _ = debug("New block #{inspect(block_number)}: #{block_hash}", opts)

    measurements = %{
      block_number: block_number
    }

    metadata = %{
      block_hash: block_hash,
      node_id: opts[:node_id]
    }

    :telemetry.execute([:node, :event_received, :new_head], measurements, metadata)
  end

  ## Logs listening

  def handle({:log, %{"result" => result}}, opts) when is_binary(result) do
    info("Listening for logs started...", opts)
  end

  def handle({:log, %{"error" => _} = data}, opts) do
    error("Failed to listen to logs: #{inspect(data)}", opts)
  end

  def handle({:log, %{"params" => _} = data}, opts) do
    transaction_hash = data["params"]["result"]["transactionHash"]

    block_number =
      data["params"]["result"]["blockNumber"]
      |> String.slice(2..-1)
      |> Base.decode16!(case: :mixed)
      |> :binary.decode_unsigned()

    log_index =
      data["params"]["result"]["logIndex"]
      |> String.slice(2..-1)
      |> Base.decode16!(case: :mixed)
      |> :binary.decode_unsigned()

    _ = debug("New log: #{inspect(data)}", opts)

    measurements = %{
      log_index: log_index,
      block_number: block_number
    }

    metadata = %{
      transaction_hash: transaction_hash,
      node_id: opts[:node_id]
    }

    :telemetry.execute([:node, :event_received, :log], measurements, metadata)
  end

  def handle({:log, data}, opts) do
    warn("Unknown logs data: #{inspect(data)}", opts)
  end

  ## New pending transactions listening

  def handle({:new_pending_transaction, %{"result" => result}}, opts)
      when is_binary(result) do
    info("Listening for new_pending_transactions started...", opts)
  end

  def handle({:new_pending_transaction, %{"error" => _} = data}, opts) do
    error("Failed to listen to new_pending_transactions: #{inspect(data)}", opts)
  end

  def handle({:new_pending_transaction, %{"params" => _} = data}, opts) do
    _ = debug("New new_pending_transactions data: #{inspect(data)}", opts)
    measurements = %{}

    metadata = %{
      transaction_hash: data["params"]["result"],
      node_id: opts[:node_id]
    }

    :telemetry.execute([:node, :event_received, :new_pending_transaction], measurements, metadata)
  end

  def handle({:new_pending_transaction, data}, opts) do
    warn("Unknown new_pending_transactions data: #{inspect(data)}", opts)
  end

  ## Sync status listening

  def handle({:sync_status, %{"result" => result}}, opts) when is_binary(result) do
    info("Listening for sync status started...", opts)
  end

  def handle({:sync_status, %{"error" => _} = data}, opts) do
    error("Failed to listen to sync status: #{inspect(data)}", opts)
  end

  def handle({:sync_status, %{"params" => %{"result" => false}}}, opts) do
    _ = debug("Sync stopped.", opts)
    measurements = %{}

    metadata = %{
      syncing: false,
      node_id: opts[:node_id]
    }

    :telemetry.execute([:node, :event_received, :new_pending_transaction], measurements, metadata)
  end

  def handle({:sync_status, %{"params" => %{"result" => result}}}, opts) do
    message = """
      Sync started.
        - Starting block: #{result["status"]["StartingBlock"]}"
        - Current block: #{result["status"]["CurrentBlock"]}"
        - Highest block: #{result["status"]["HighestBlock"]}"
      """

    _ = debug(message, opts)

    measurements = %{
      current_block: result["status"]["CurrentBlock"],
      highest_block: result["status"]["HighestBlock"]
    }

    metadata = %{
      syncing: true,
      node_id: opts[:node_id]
    }

    :telemetry.execute([:node, :event_received, :sync_status], measurements, metadata)
  end

  def handle({type, data}, opts) do
    warn("Unknown event #{inspect(type)} with data: #{inspect(data)}", opts)
  end

  defp debug(message, opts), do: message |> prefix_with(opts) |> Logger.debug()
  defp info(message, opts), do: message |> prefix_with(opts) |> Logger.info()
  defp warn(message, opts), do: message |> prefix_with(opts) |> Logger.warn()
  defp error(message, opts), do: message |> prefix_with(opts) |> Logger.error()

  defp prefix_with(message, opts), do: "#{opts[:label]} (#{inspect(opts[:pid])}): #{message}"
end
