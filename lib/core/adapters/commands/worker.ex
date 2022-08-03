# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.
#

defmodule Core.Adapters.Commands.Worker do
  @moduledoc """
  Adapter to send commands to a worker actor.
  Currently implemented commands: invocation.
  """
  require Logger
  alias Core.Domain.FunctionStruct
  @behaviour Core.Domain.Ports.Commands

  @impl true
  def send_invocation_command(worker, %FunctionStruct{} = function, args) do
    worker_addr = worker_address(worker)
    cmd = invoke_command(function, args)

    call_worker(worker_addr, cmd)
  end

  @doc false
  def worker_address(worker), do: {:worker, worker}

  def invoke_command(%FunctionStruct{} = function, args) do
    {:invoke, function, args}
  end

  defp call_worker(worker_addr, {cmd, payload, _args} = command) do
    Logger.info(
      "sending command #{cmd} to #{inspect(worker_addr)} with payload #{inspect(payload)}"
    )

    GenServer.call(worker_addr, command, 300_000)
  end
end
