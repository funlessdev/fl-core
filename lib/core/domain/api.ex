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
defmodule Core.Domain.Api do
  @moduledoc """
  Provides functions to deal with requests to workers.
  """
  require Logger
  alias Core.Domain.FunctionStruct
  alias Core.Domain.InvokeParams
  alias Core.Domain.Nodes
  alias Core.Domain.Ports.Commands
  alias Core.Domain.Ports.FunctionStorage
  alias Core.Domain.Scheduler

  @spec invoke(Map.t()) :: {:ok, %{:result => String.t()}} | {:error, any}
  @doc """
  Sends an invocation request for the `name` function in the `ns` namespace,
  specified in the invocation parameters.

  The request is sent with the worker adapter to a worker chosen from the `worker_nodes`, if any.

  ## Parameters
    - ivk_params: a map with namespace name, function name and a map of args.
  """
  def invoke(%{"function" => f} = raw_params) do
    # not pretty, but we avoid calling Map.keys() on each invocation
    keys = ["function", "namespace", "args"]

    parsed_params =
      raw_params |> Map.take(keys) |> Map.new(fn {k, v} -> {String.to_existing_atom(k), v} end)

    ivk_params = struct(InvokeParams, parsed_params)
    Logger.info("API: received invocation for function #{f} with params #{inspect(ivk_params)}")

    Nodes.worker_nodes() |> Scheduler.select() |> invoke_on_chosen(ivk_params)
  end

  def invoke(_), do: {:error, :bad_params}

  defp invoke_on_chosen(:no_workers, _) do
    Logger.warn("API: no workers found")
    {:error, :no_workers}
  end

  defp invoke_on_chosen(worker, ivk_params) do
    Logger.info("API: found worker #{worker} for invocation")
    f = FunctionStorage.get_function(ivk_params.function, ivk_params.namespace)

    case f do
      {:ok, function} ->
        wrk_reply = Commands.send_invocation_command(worker, function, ivk_params.args)
        parse_wrk_reply(wrk_reply)

      {:error, :not_found} ->
        {:error, :not_found}

      {:error, err} ->
        Logger.error(
          "API: encountered error when getting function #{ivk_params.function}: #{inspect(err)}"
        )

        {:error, err}
    end
  end

  defp parse_wrk_reply({:ok, _} = reply) do
    Logger.info("API: received success reply from worker")
    reply
  end

  defp parse_wrk_reply({:error, err}) do
    err_msg = err["error"] || "Unknown error"
    Logger.error("API: received error reply from worker #{err_msg}")
    {:error, :worker_error}
  end

  def new_function(%{"name" => name, "code" => code, "image" => image} = raw_params) do
    function = %FunctionStruct{
      name: name,
      namespace: raw_params["namespace"] || "_",
      image: image,
      code: code
    }

    Logger.info(
      "API: received creation request for function #{function.name} in namespace #{function.namespace}"
    )

    FunctionStorage.insert_function(function)
  end

  def new_function(_), do: {:error, :bad_params}

  def delete_function(name, namespace) do
    Logger.info("API: received deletion request for function #{name} in namespace #{namespace}")
    FunctionStorage.delete_function(name, namespace)
  end
end
