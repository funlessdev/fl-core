# Copyright 2023 Giuseppe De Palma, Matteo Trentin
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

defmodule Integration.CleanupEtsTest do
  use ExUnit.Case

  alias Data.ExecutionResource
  alias Worker.Adapters.ResourceCache
  alias Worker.Domain.CleanupResource

  import Mox, only: [verify_on_exit!: 1]

  setup :verify_on_exit!

  describe "Cleanup requests" do
    setup do
      Worker.Cleaner.Mock |> Mox.stub_with(Worker.Adapters.Runtime.Cleaner.Test)
      Worker.ResourceCache.Mock |> Mox.stub_with(Worker.Adapters.ResourceCache)
      Worker.RawResourceStorage.Mock |> Mox.stub_with(Worker.Adapters.RawResourceStorage.Test)
      :ok
    end

    test "cleanup should remove resource from cache when successfull" do
      function = %{name: "fn", module: "ns", hash: <<0, 0, 0>>, code: ""}

      resource = %ExecutionResource{resource: "a-resource"}

      ResourceCache.insert("fn", "ns", function.hash, resource)
      assert ResourceCache.get("fn", "ns", function.hash) == resource

      assert CleanupResource.cleanup(function) == :ok
      assert ResourceCache.get("fn", "ns", function.hash) == :resource_not_found
    end

    test "cleanup should call cleaner passing it the resource from the cache" do
      function = %{name: "fn", module: "ns", hash: <<0, 0, 0>>, code: ""}

      resource = %ExecutionResource{resource: "a-resource"}

      ResourceCache.insert("fn", "ns", function.hash, resource)
      assert ResourceCache.get("fn", "ns", function.hash) == resource

      # If we are not passing the resource to the cleaner, this will fail
      # I don't know how to expect a certain parameter to be passed to a function, so this will do
      Worker.Cleaner.Mock |> Mox.expect(:cleanup, 1, fn res -> if res == resource, do: :ok end)

      assert CleanupResource.cleanup(function) == :ok
    end

    test "cleanup should return resource_not_found when not found" do
      Worker.RawResourceStorage.Mock |> Mox.expect(:delete, fn _, _, _ -> {:error, :enoent} end)

      function = %{name: "fn", module: "ns", hash: <<0, 0, 0>>, code: ""}

      assert ResourceCache.get("fn", "ns", function.hash) == :resource_not_found
      assert CleanupResource.cleanup(function) == {:error, :resource_not_found}
    end
  end
end
