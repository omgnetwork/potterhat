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

defmodule PotterhatNode.MockEthereumNode.RPC do
  @moduledoc """
  The mock RPC router for the Ethereum node mock.
  """
  use Plug.Router

  plug(Plug.Parsers, parsers: [:json], json_decoder: Jason)

  plug(:match)
  plug(:dispatch)

  post "/" do
    response =
      conn
      |> generate_response()
      |> Jason.encode!()

    send_resp(conn, 200, response)
  end

  match _ do
    send_resp(conn, 200, "Invalid request")
  end

  def generate_response(conn) do
    conn.body_params
    |> Map.fetch!("method")
    |> do_generate_response(conn)
  end

  defp do_generate_response("web3_clientVersion", conn) do
    %{
      "id" => conn.body_params["id"],
      "jsonrpc" => "2.0",
      "result" => "PotterhatMockEthereumNode"
    }
  end

  defp do_generate_response(_, conn) do
    %{
      "id" => conn.body_params["id"],
      "jsonrpc" => "2.0",
      "error" => %{
        "code" => -32_601,
        "message" => "Method not found"
      }
    }
  end
end
