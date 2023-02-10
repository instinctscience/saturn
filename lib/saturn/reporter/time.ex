defmodule Saturn.Reporter.Time do
  @moduledoc false

  # Report that shows queries listed by their total time consumption, descending

  @behaviour Saturn.Reporter
  import Saturn.Reporter.Util

  @impl Saturn.Reporter
  def report(queries) do
    queries
    |> Enum.map(fn {query, stats} -> {query, query_time(stats.time)} end)
    |> Enum.sort_by(&elem(&1, 1), :desc)
    |> Enum.map(&format/1)
    |> Enum.join("\n\n")
  end

  defp query_time(time) do
    time && System.convert_time_unit(time, :native, :millisecond)
  end

  defp format({query, time}) do
    formatted_stacktrace = if(query.stacktrace, do: format_stacktrace(query.stacktrace), else: "")

    """
    Query: #{inspect(query.query)}
    Time: #{time} ms
    #{formatted_stacktrace}\
    """
  end
end
