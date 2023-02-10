defmodule Saturn do
  @moduledoc """
  Saturn, the child-eating monster, is here to devour the N of your N+1 queries.
  """

  alias __MODULE__.Aggregator
  alias __MODULE__.Reporter

  @doc """
  Handles query telemetry events from Ecto, should not be called directly.
  """
  defdelegate handle_query(name, measurements, metadata, config), to: Aggregator

  @doc """
  Allow Saturn to begin collecting query events.
  """
  defdelegate enable(), to: Aggregator

  @doc """
  Disallow Saturn from collecting new query events.  Stored query events are
  kept; use `clear/0` to clear them.
  """
  defdelegate disable(), to: Aggregator

  @doc """
  Clear all stored query events.
  """
  defdelegate clear(), to: Aggregator

  @typedoc """
  Identifiers for the available reports.  See `report/0` for more information.
  """
  @type report_specifier :: :count | :time | :prof

  @doc """
  Print a report to the console.

  Each report aggregates information about the stored queries and formats it for
  human consumption.  There are currently three reports:

  - `:prof` :: Report that shows a tree-like view of the aggregated query's
    sources and associated costs.  The goal of this report is to help
    identify which _functions_ within a codebase are responsible for
    a disproportionate amount of cost.
  - `:count` :: Lists queries, with how many times each has been called and its
    stacktrace, orderd by how many times it has been called.
  - `:time` :: Lists queries, with how much time each query has consumed and its
    stacktrace, orderd by total time consumed.
  """
  @spec report() :: :ok
  @spec report(report_specifier()) :: :ok
  def report(by \\ :count) do
    Aggregator.queries()
    |> Reporter.report(by)
    |> IO.puts()
  end
end
