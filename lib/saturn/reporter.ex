defmodule Saturn.Reporter do
  @callback export(%{Saturn.Query.t() => Saturn.QueryStats.t()}) :: term()

  @type reporter_specifier :: :count | :time

  @spec export(reporter_specifier, %{Query.t() => QueryStats.t()}) :: term()
  def export(by, queries) do
    reporter(by).export(queries)
  end

  # Lacks the extensibility of Viz's approach, but doesn't require
  # string-manipulation metaprogramming.
  defp reporter(:count), do: __MODULE__.Count
  defp reporter(:time), do: __MODULE__.Time
end
