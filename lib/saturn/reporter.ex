defmodule Saturn.Reporter do
  @moduledoc false

  # A behaviour-dispatcher for generating reports.
  # This module specifies a behaviour for reporters to adhere to and has a
  # `report` function that dispatches to the requested reporter.

  @callback report(%{Saturn.Query.t() => Saturn.QueryStats.t()}) :: String.t()

  @spec report(%{Saturn.Query.t() => Saturn.QueryStats.t()}, Saturn.report_specifier()) ::
          String.t()
  def report(queries, by) do
    reporter(by).report(queries)
  end

  # Lacks the extensibility of Viz's approach, but doesn't require
  # string-manipulation metaprogramming.
  defp reporter(:count), do: __MODULE__.Count
  defp reporter(:time), do: __MODULE__.Time
  defp reporter(:prof), do: __MODULE__.Prof
end
