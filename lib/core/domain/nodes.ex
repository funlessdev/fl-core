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
defmodule Core.Domain.Nodes do
  @moduledoc """
  Contains utility functions to get processed info about the cluster,
  using the Cluster port.
  """

  alias Core.Domain.Ports.Cluster

  @doc """
  Obtains all nodes in the cluster and filters the ones with 'worker' as their sname.
  """
  def worker_nodes do
    Cluster.all_nodes()
    |> Enum.map(&Atom.to_string(&1))
    |> Enum.filter(fn node_name -> String.contains?(node_name, "worker") end)
    |> Enum.map(fn node_name -> String.to_atom(node_name) end)
  end

  def core_nodes do
    [
      node()
      | Cluster.all_nodes()
        |> Enum.map(&Atom.to_string(&1))
        |> Enum.filter(fn node_name -> String.contains?(node_name, "core") end)
        |> Enum.map(fn node_name -> String.to_atom(node_name) end)
    ]
  end
end
