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

defmodule PotterhatRPC.RouterTest do
  use ExUnit.Case, async: true
  use Plug.Test
  alias PotterhatRPC.Router

  describe "GET /" do
    test "returns status, version and node stats" do
      response =
        :get
        |> conn("/")
        |> Router.call(Router.init([]))
        |> Map.fetch!(:resp_body)
        |> Jason.decode!()

      expected = %{
        "status" => true,
        "potterhat_version" => Application.get_env(:potterhat_rpc, :version),
        "nodes" => %{
          "total" => 0,
          "active" => 0
        }
      }

      assert expected == response
    end
  end
end
