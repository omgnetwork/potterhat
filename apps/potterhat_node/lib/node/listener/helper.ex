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

defmodule PotterhatNode.Listener.Helper do
  @moduledoc """
  Helper functions for listeners.
  """

  @doc """
  Broadcast the given message to all linked processes.
  """
  @spec broadcast(any()) :: :ok
  def broadcast(message) do
    {:links, links} = Process.info(self(), :links)

    _ = Enum.each(parents, fn
      link when is_pid(link) ->
        :ok = GenServer.cast(link, message)

      _ ->
        :skip
    end)

    :ok
  end
end
