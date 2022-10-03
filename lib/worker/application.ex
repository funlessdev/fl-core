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

defmodule Worker.Application do
  @moduledoc false
  alias Worker.Adapters
  use Application

  @impl true
  def start(_type, _args) do
    topologies = Application.get_env(:libcluster, :topologies)

    children = [
      {Cluster.Supervisor, [topologies, [name: Worker.ClusterSupervisor]]},
      {Adapters.RuntimeTracker.ETS.WriteServer, []},
      {Adapters.Requests.Cluster.Server, []},
      {Adapters.Telemetry.Supervisor, []}
    ]

    Supervisor.start_link(children, strategy: :rest_for_one)
  end

  def docker_socket do
    default = "unix:///var/run/docker.sock"
    docker_env = System.get_env("DOCKER_HOST", default)

    case Regex.run(~r/^((unix|tcp|http):\/\/)(.*)$/, docker_env) do
      nil -> default
      [socket | _] -> socket
    end
  end
end
