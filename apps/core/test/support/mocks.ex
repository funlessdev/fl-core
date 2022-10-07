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

Mox.defmock(Core.Commands.Mock, for: Core.Domain.Ports.Commands)
Mox.defmock(Core.Cluster.Mock, for: Core.Domain.Ports.Cluster)
Mox.defmock(Core.FunctionStore.Mock, for: Core.Domain.Ports.FunctionStore)
Mox.defmock(Core.Telemetry.Api.Mock, for: Core.Domain.Ports.Telemetry.Api)
