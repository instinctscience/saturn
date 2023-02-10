defmodule Saturn.Reporter do
  @callback report(%{Saturn.Query.t() => Saturn.QueryStats.t()}) :: String.t()

  @type reporter_specifier :: :count | :time | :prof

  @spec report(%{Saturn.Query.t() => Saturn.QueryStats.t()}, reporter_specifier) :: String.t()
  def report(queries, by) do
    reporter(by).report(queries)
  end

  # Lacks the extensibility of Viz's approach, but doesn't require
  # string-manipulation metaprogramming.
  defp reporter(:count), do: __MODULE__.Count
  defp reporter(:time), do: __MODULE__.Time
  defp reporter(:prof), do: __MODULE__.Prof
end
