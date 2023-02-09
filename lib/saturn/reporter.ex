defmodule Saturn.Reporter do
  @callback report(%{Saturn.Query.t() => Saturn.QueryStats.t()}) :: term()

  @type reporter_specifier :: :count | :time | :prof

  @spec report(reporter_specifier, %{Saturn.Query.t() => Saturn.QueryStats.t()}) :: term()
  def report(by, queries) do
    reporter(by).report(queries)
  end

  # Lacks the extensibility of Viz's approach, but doesn't require
  # string-manipulation metaprogramming.
  defp reporter(:count), do: __MODULE__.Count
  defp reporter(:time), do: __MODULE__.Time
  defp reporter(:prof), do: __MODULE__.Prof
end
