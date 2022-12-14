defmodule Saturn do
  @moduledoc """
  Saturn, the child-eating monster, is here to devour the N of your N+1 queries.
  """

  defdelegate handle_query(name, measurements, metadata, config), to: __MODULE__.Aggregator
  defdelegate top_offenders(num), to: __MODULE__.Aggregator
  defdelegate clear(), to: __MODULE__.Aggregator
end
