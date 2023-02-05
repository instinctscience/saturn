defmodule Saturn.Query do
  @type stacktrace :: [
          {module, atom, non_neg_integer, [file: charlist(), line: non_neg_integer()]}
        ]
  @type t :: %__MODULE__{query: String.t(), stacktrace: stacktrace() | nil}

  @enforce_keys [:query]
  defstruct [:query, :stacktrace]
end
