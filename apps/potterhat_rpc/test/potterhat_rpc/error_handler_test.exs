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

defmodule PotterhatRPC.ErrorHandlerTest do
  use ExUnit.Case, async: true
  use Plug.Test
  alias PotterhatRPC.ErrorHandler

  describe "send_resp/3" do
    test "puts the error object into the connection's response body" do
      conn = conn(:get, "/some_url")
      refute conn.resp_body

      error_conn = ErrorHandler.send_resp(conn, :no_nodes_available, 1234)

      expected = Jason.encode!(%{
        "jsonrpc" => "2.0",
        "id" => 1234,
        "error" => %{
          "code" => -32099,
          "message" => "No backend nodes available."
        }
      })

      assert expected == error_conn.resp_body
    end
  end
end
