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

defmodule PotterhatNodeTest do
  use ExUnit.Case, async: true

  doctest PotterhatNode

  describe "all/0" do
    test "returns the node configs" do
      assert PotterhatNode.all() == Application.get_env(:potterhat_node, :nodes)
    end
  end

  describe "count/0" do
    test "returns the node configs" do
      assert PotterhatNode.count() == length(Application.get_env(:potterhat_node, :nodes))
    end
  end
end
