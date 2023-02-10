defmodule Saturn.Reporter.Count do
  @behaviour Saturn.Reporter
  import Saturn.Reporter.Util

  @impl Saturn.Reporter
  def report(queries) do
    queries
    |> Enum.map(fn {query, stats} -> {query, stats.count} end)
    |> Enum.sort_by(&elem(&1, 1), :desc)
    |> Enum.map(&format/1)
    |> Enum.join("\n\n")
  end

  defp format({query, count}) do
    formatted_stacktrace = if(query.stacktrace, do: format_stacktrace(query.stacktrace), else: "")

    """
    Query: #{inspect(query.query)}
    Count: #{count}
    #{formatted_stacktrace}\
    """
  end
end
