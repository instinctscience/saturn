defmodule Saturn.Reporter.Time do
  @behaviour Saturn.Reporter

  @impl Saturn.Reporter
  def export(queries) do
    {:ok,
     queries
     |> Enum.map(fn {query, stats} -> {query, query_time(stats.time)} end)
     |> Enum.sort_by(&elem(&1, 1), :desc)}
  end

  defp query_time(time) do
    time && System.convert_time_unit(time, :native, :millisecond)
  end
end
