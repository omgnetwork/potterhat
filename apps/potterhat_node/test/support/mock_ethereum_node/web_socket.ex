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

defmodule PotterhatNode.MockEthereumNode.WebSocket do
  @moduledoc """
  The mock WebSocket server router for the Ethereum node mock.
  """
  # This module is heavily inspired by WebSockex.TestServer.
  # See https://github.com/Azolo/websockex/blob/master/test/support/test_server.ex
  @behaviour :cowboy_websocket

  def init(req, [{test_pid, agent_pid}] = state) do
    case Agent.get(agent_pid, fn x -> x end) do
      :ok ->
        send(test_pid, self())
        {:cowboy_websocket, req, state}

      int when is_integer(int) ->
        _ = :cowboy_req.reply(int, req)
        {:shutdown, req, :tests_are_fun}

      :connection_wait ->
        send(test_pid, self())

        receive do
          :connection_continue ->
            {:upgrade, :protocol, :cowboy_websocket}
        end

      :immediate_reply ->
        immediate_reply(req)
    end
  end

  def terminate(_, _), do: :ok

  def websocket_init(_, [{test_pid, agent_pid}]) do
    send(test_pid, self())
    {:ok, %{pid: test_pid, agent_pid: agent_pid}}
  end

  def websocket_terminate({:remote, :closed}, state) do
    send(state.pid, :normal_remote_closed)
  end

  def websocket_terminate({:remote, close_code, reason}, state) do
    send(state.pid, {close_code, reason})
  end

  def websocket_terminate(_, _) do
    :ok
  end

  def websocket_handle({:text, encoded_json}, state) do
    decoded = Jason.decode!(encoded_json)
    reply = handle_message(decoded)

    {:reply, {:text, reply}, state}
  end

  def websocket_handle({:binary, msg}, state) do
    send(state.pid, :erlang.binary_to_term(msg))
    {:ok, state}
  end

  def websocket_handle({:ping, _}, state), do: {:ok, state}

  def websocket_handle({:pong, ""}, state) do
    send(state.pid, :received_pong)
    {:ok, state}
  end

  def websocket_handle({:pong, payload}, %{ping_payload: ping_payload} = state)
      when payload == ping_payload do
    send(state.pid, :received_payload_pong)
    {:ok, state}
  end

  defp handle_message(%{"method" => "eth_subscribe", "params" => ["newHeads"]}) do
    Jason.encode!(%{
      "jsonrpc" => "2.0",
      "id" => 2,
      "result" => "0xcd0c3e8af590364c09d0fa6a1210faf5"
    })
  end

  defp handle_message(%{"method" => "eth_subscribe", "params" => ["logs", _]}) do
    Jason.encode!(%{
      "jsonrpc" => "2.0",
      "id" => 2,
      "result" => "0x4a8a4c0517381924f9838102c5a4dcb7"
    })
  end

  defp handle_message(%{"method" => "eth_subscribe", "params" => ["newPendingTransactions"]}) do
    Jason.encode!(%{
      "jsonrpc" => "2.0",
      "id" => 2,
      "result" => "0xc3b33aa549fb9a60e95d21862596617c"
    })
  end

  defp handle_message(%{"method" => "eth_subscribe", "params" => ["syncing"]}) do
    Jason.encode!(%{
      "jsonrpc" => "2.0",
      "id" => 1,
      "result" => "0xe2ffeb2703bcf602d42922385829ce96"
    })
  end

  def websocket_info(:stall, _) do
    Process.sleep(:infinity)
  end

  def websocket_info(:send_ping, state), do: {:reply, :ping, state}

  def websocket_info(:send_payload_ping, state) do
    payload = "Llama and Lambs"
    {:reply, {:ping, payload}, Map.put(state, :ping_payload, payload)}
  end

  def websocket_info(:close, state), do: {:reply, :close, state}

  def websocket_info({:close, code, reason}, state) do
    {:reply, {:close, code, reason}, state}
  end

  def websocket_info({:send, frame}, state) do
    {:reply, frame, state}
  end

  def websocket_info({:set_code, code}, state) do
    Agent.update(state.agent_pid, fn _ -> code end)
    {:ok, state}
  end

  def websocket_info(:connection_wait, state) do
    Agent.update(state.agent_pid, fn _ -> :connection_wait end)
    {:ok, state}
  end

  def websocket_info(:immediate_reply, state) do
    Agent.update(state.agent_pid, fn _ -> :immediate_reply end)
    {:ok, state}
  end

  def websocket_info(:shutdown, state) do
    {:shutdown, state}
  end

  def websocket_info(_, state), do: {:ok, state}

  @dialyzer {:nowarn_function, immediate_reply: 1}
  defp immediate_reply(req) do
    socket = elem(req, 1)
    transport = elem(req, 2)
    {headers, _} = :cowboy_req.headers(req)
    {_, key} = List.keyfind(headers, "sec-websocket-key", 0)

    challenge =
      :crypto.hash(:sha, key <> "258EAFA5-E914-47DA-95CA-C5AB0DC85B11") |> Base.encode64()

    handshake =
      [
        "HTTP/1.1 101 Test Socket Upgrade",
        "Connection: Upgrade",
        "Upgrade: websocket",
        "Sec-WebSocket-Accept: #{challenge}",
        "\r\n"
      ]
      |> Enum.join("\r\n")

    frame = <<1::1, 0::3, 1::4, 0::1, 15::7, "Immediate Reply">>
    transport.send(socket, handshake)
    Process.sleep(0)
    transport.send(socket, frame)

    Process.sleep(:infinity)
  end
end
