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

defmodule Potterhat.Node.Subscription do
  @moduledoc """
  The namespace for Ethereum event subscribers.

  Although it is theoretically possible to subscribe to multiple events in one websocket connection,
  there are discrepancies between each client.

  For example, Geth would return a generated subscription id without requiring the request
  to provide a subscription id. On the other had, Infura requires a subscription id,
  but returns a different one anyway.
  """
end
