defmodule Saturn.Aggregator do
  @moduledoc false

  use Agent

  alias Saturn.Query
  alias Saturn.QueryStats

  defmodule State do
    @type t :: %__MODULE__{
            enabled: boolean(),
            queries: %{Query.t() => QueryStats.t()}
          }
    defstruct enabled: false, queries: %{}
  end

  # measurements:
  # %{decode_time: 5950, idle_time: 1199657146, query_time: 111592975, queue_time: 863357, total_time: 112462282}
  # %{decode_time: 2600, query_time: 123814, total_time: 126414}
  # %{query_time: 144045, total_time: 144045}
  def handle_query(
        [_app, :repo, :query],
        measurements,
        %{query: query} = metadata,
        _config
      ) do
    update_stats(
      %Query{
        query: query,
        stacktrace: Map.get(metadata, :stacktrace)
      },
      %QueryStats{
        count: 1,
        time: Map.get(measurements, :total_time)
      }
    )
  end

  def queries() do
    Agent.get(__MODULE__, & &1.queries)
  end

  def enable() do
    Agent.update(__MODULE__, fn state -> %State{state | enabled: true} end)
  end

  def disable() do
    Agent.update(__MODULE__, fn state -> %State{state | enabled: false} end)
  end

  def clear() do
    Agent.update(__MODULE__, fn state -> %State{state | queries: %{}} end)
  end

  def start_link(opts) do
    enabled = Keyword.get(opts, :enable, false)
    Agent.start_link(fn -> %State{enabled: enabled} end, name: __MODULE__)
  end

  defp update_stats(query, query_stats) do
    if Agent.get(__MODULE__, & &1.enabled) do
      Agent.update(__MODULE__, fn state = %State{queries: queries} ->
        %State{
          state
          | queries: Map.update(queries, query, query_stats, &merge_stats(&1, query_stats))
        }
      end)
    end
  end

  defp merge_stats(
         %QueryStats{count: count1, time: time1},
         %QueryStats{count: count2, time: time2}
       ),
       do: %QueryStats{count: count1 + count2, time: time1 + time2}
end
