defmodule Saturn.QueryStats do
  @moduledoc false

  # A struct that holds statistics associated to a query

  @type t :: %__MODULE__{count: pos_integer(), time: pos_integer() | nil}
  defstruct [:count, :time]
end
