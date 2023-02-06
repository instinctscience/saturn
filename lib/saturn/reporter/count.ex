defmodule Saturn.Reporter.Count do
  @behaviour Saturn.Reporter

  @impl Saturn.Reporter
  def report(queries) do
    {:ok,
     queries
     |> Enum.map(fn {query, stats} -> {query, stats.count} end)
     |> Enum.sort_by(&elem(&1, 1), :desc)}
  end
end
