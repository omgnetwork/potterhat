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

defmodule PotterhatUtils.BaseLogger do
  @moduledoc """
  Common logger utilities.
  """
  require Logger

  def debug(message, meta), do: message |> prefix_with(meta) |> Logger.debug()
  def info(message, meta), do: message |> prefix_with(meta) |> Logger.info()
  def warn(message, meta), do: message |> prefix_with(meta) |> Logger.warn()
  def error(message, meta), do: message |> prefix_with(meta) |> Logger.error()

  def prefix_with(message, %{node_id: _} = meta), do: "#{meta.node_id}: #{message}"
  def prefix_with(message, meta), do: message
end
