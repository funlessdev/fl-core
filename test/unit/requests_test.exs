# Copyright 2022 Giuseppe De Palma, Matteo Trentin
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

defmodule RequestTest do
  use ExUnit.Case
  alias Worker.Adapters.Requests.Cluster
  alias Worker.Domain.RuntimeStruct
  import Mox, only: [verify_on_exit!: 1, set_mox_global: 1]

  setup :set_mox_global
  setup :verify_on_exit!

  setup_all do
    function = %{
      name: "hellojs",
      namespace: "_",
      image: "nodejs",
      code: "console.log(\"hello\")"
    }

    %{function: function}
  end

  describe "Cluster" do
    setup do
      Worker.Provisioner.Mock |> Mox.stub_with(Worker.Adapters.Runtime.Provisioner.Test)
      Worker.Runner.Mock |> Mox.stub_with(Worker.Adapters.Runtime.Runner.Test)
      Worker.Cleaner.Mock |> Mox.stub_with(Worker.Adapters.Runtime.Cleaner.Test)
      Worker.RuntimeCache.Mock |> Mox.stub_with(Worker.Adapters.RuntimeCache.Test)

      Application.stop(Cluster.Server)
      {:ok, pid} = GenServer.start(Cluster.Server, [])
      %{pid: pid}
    end

    test "invoke call should return {:ok, %{result => ..}} when no errors occur", %{
      pid: pid,
      function: function
    } do
      expected = {:ok, %{"result" => "test-output"}}
      assert GenServer.call(pid, {:invoke, function}) == expected
    end

    test "invoke call should retrieve a runtime and run the function", %{
      pid: pid,
      function: function
    } do
      Worker.RuntimeCache.Mock
      |> Mox.expect(:get, fn _, _ -> :runtime_not_found end)

      Worker.Provisioner.Mock
      |> Mox.expect(:provision, fn _ ->
        {:ok, %RuntimeStruct{name: "hello-runtime", host: "localhost", port: "8080"}}
      end)

      reply = GenServer.call(pid, {:invoke, function})

      assert reply == {:ok, %{"result" => "test-output"}}
    end

    # test "invoke call should return back an error as map when it occurs during invocation", %{
    #   pid: pid,
    #   function: function
    # } do
    #   Worker.Runner.Mock
    #   |> Mox.expect(:run_function, fn _, _, _ -> {:error, "runtime error during invocation"} end)

    #   reply = GenServer.call(pid, {:invoke, function})
    #   expected = {:error, "runtime error during invocation"}
    #   assert reply == expected
    # end

    # test "invoke with args should return {:ok, %{result => ..}} when no errors occur", %{
    #   pid: pid,
    #   function: function
    # } do
    #   expected = {:ok, %{"result" => "test-output"}}
    #   reply = GenServer.call(pid, {:invoke, function, %{"arg1" => "value1"}})
    #   assert expected == reply
    # end

    # test "cleanup call should return {:ok, runtime} when no error occurs", %{
    #   pid: pid,
    #   function: function
    # } do
    #   assert :ok = GenServer.call(pid, {:cleanup, function})
    # end

    # test "cleanup call should return back an error when it occurs during cleanup", %{
    #   pid: pid,
    #   function: function
    # } do
    #   expected = {:error, "cleanup error"}

    #   Worker.Cleaner.Mock
    #   |> Mox.expect(:cleanup, fn _ -> {:error, "cleanup error"} end)

    #   reply = GenServer.call(pid, {:cleanup, function})
    #   assert reply == expected
    # end
  end
end
