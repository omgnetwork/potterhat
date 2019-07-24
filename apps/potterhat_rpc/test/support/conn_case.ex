# Copyright 2018-2019 OmiseGO Pte Ltd
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

defmodule PotterhatRPC.ConnCase do
  @moduledoc """
  Case template for all tests that require interaction with Plug.Conn and Plug.Router.
  """
  use ExUnit.CaseTemplate
  use Plug.Test

  using do
    quote do
      import unquote(__MODULE__)
    end
  end

  def call(router, method, path, params \\ nil) do
    method
    |> conn(path, params)
    |> put_req_header("content-type", "application/json")
    |> router.call(router.init([]))
  end

  def json_response(conn) do
    conn
    |> Map.fetch!(:resp_body)
    |> Jason.decode!()
  end
end
