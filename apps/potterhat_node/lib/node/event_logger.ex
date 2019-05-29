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

  ## New block listening

  def log_event({:new_heads, %{"result" => result}}, opts) when is_binary(result) do
    info("Listening for new heads started...", opts)
  end

  def log_event({:new_heads, %{"error" => _} = data}, opts) do
    error("Failed to listen to new heads: #{inspect(data)}", opts)
  end

  def log_event({:new_heads, data}, opts) do
    block_hash = data["params"]["result"]["hash"]

    block_number =
      data["params"]["result"]["number"]
      |> String.slice(2..-1)
      |> Base.decode16!(case: :mixed)
      |> :binary.decode_unsigned()

    debug("New block #{inspect block_number}: #{block_hash}", opts)
  end

  ## Logs listening

  def log_event({:logs, %{"result" => result}}, opts) when is_binary(result) do
    info("Listening for logs started...", opts)
  end

  def log_event({:logs, %{"error" => _} = data}, opts) do
    error("Failed to listen to logs: #{inspect(data)}", opts)
  end

  def log_event({:logs, %{"params" => _} = log}, opts) do
    debug("New log: #{inspect(log)}", opts)
  end

  def log_event({:logs, data}, opts) do
    warn("Unknown logs data: #{inspect(data)}", opts)
  end

  ## New pending transactions listening

  def log_event({:new_pending_transactions, %{"result" => result}}, opts) when is_binary(result) do
    info("Listening for new_pending_transactions started...", opts)
  end

  def log_event({:new_pending_transactions, %{"error" => _} = data}, opts) do
    error("Failed to listen to new_pending_transactions: #{inspect(data)}", opts)
  end

  def log_event({:new_pending_transactions, %{"params" => _} = txn}, opts) do
    debug("New new_pending_transactions data: #{inspect(txn)}", opts)
  end

  def log_event({:new_pending_transactions, data}, opts) do
    warn("Unknown new_pending_transactions data: #{inspect(data)}", opts)
  end

  ## Sync status listening

  def log_event({:sync_status, %{"result" => result}}, opts) when is_binary(result) do
    info("Listening for sync status started...", opts)
  end

  def log_event({:sync_status, %{"error" => _} = data}, opts) do
    error("Failed to listen to sync status: #{inspect(data)}", opts)
  end

  def log_event({:sync_status, %{"params" => %{"result" => false}}}, opts) do
    debug("Sync stopped.", opts)
  end

  def log_event({:sync_status, %{"params" => %{"result" => result}}}, opts) do
    message =
      """
      Sync started.
        - Starting block: #{result["status"]["StartingBlock"]}"
        - Current block: #{result["status"]["CurrentBlock"]}"
        - Highest block: #{result["status"]["HighestBlock"]}"
      """

    debug(message, opts)
  end

  defp debug(message, opts), do: message |> prefix_with(opts) |> Logger.debug()
  defp info(message, opts), do: message |> prefix_with(opts) |> Logger.info()
  defp warn(message, opts), do: message |> prefix_with(opts) |> Logger.warn()
  defp error(message, opts), do: message |> prefix_with(opts) |> Logger.error()

  defp prefix_with(message, opts), do: "#{opts[:label]} (#{inspect(opts[:pid])}): #{message}"
end
