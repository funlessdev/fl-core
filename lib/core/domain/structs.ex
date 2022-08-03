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
defmodule Core.Domain.FunctionStruct do
  @moduledoc """
    Function struct, used for insertion in permanent storage.

    ## Fields
      - name: function name
      - namespace: function namespace
      - code: function code as a string
      - language: language in which the function is written
  """
  @type t :: %__MODULE__{
          namespace: String.t(),
          name: String.t(),
          code: String.t(),
          language: String.t()
        }
  @enforce_keys [:name, :namespace, :code, :language]
  defstruct [:name, :namespace, :code, :language]
end

defmodule Core.Domain.InvokeParams do
  @moduledoc """
    Invocation parameters struct, used for parameter validation.

    ## Fields
      - namespace: function namespace
      - function: function name
      - args: function arguments
  """
  @type t :: %__MODULE__{
          namespace: String.t(),
          function: String.t(),
          args: Map.t()
        }
  @enforce_keys [:function]
  defstruct [:function, namespace: "_", args: %{}]
end
