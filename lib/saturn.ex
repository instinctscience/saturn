defmodule Saturn do
  @moduledoc """
  Saturn, the child-eating monster, is here to devour the N of your N+1 queries.
  """

  alias __MODULE__.Aggregator
  alias __MODULE__.Reporter

  defdelegate handle_query(name, measurements, metadata, config), to: Aggregator
  defdelegate enable(), to: Aggregator
  defdelegate disable(), to: Aggregator
  defdelegate clear(), to: Aggregator

  def report(by \\ :count) do
    Aggregator.queries()
    |> Reporter.report(by)
    |> IO.puts()
  end
end
