defmodule Saturn.QueryStats do
  @type t :: %__MODULE__{count: pos_integer(), time: pos_integer() | nil}
  defstruct [:count, :time]
end
