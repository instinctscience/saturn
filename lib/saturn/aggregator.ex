defmodule Saturn.Aggregator do
  use Agent

  @aggregate_mappings %{
    count: &__MODULE__.by_count/1,
    time: &__MODULE__.by_time/1
  }

  defmodule State do
    @type t :: %__MODULE__{
            enabled: boolean(),
            queries: %{Saturn.Aggregator.Query.t() => Saturn.Aggregator.QueryStats.t()}
          }
    defstruct enabled: false, queries: %{}
  end

  defmodule Query do
    @type stacktrace :: [
            {module, atom, non_neg_integer, [file: charlist(), line: non_neg_integer()]}
          ]
    @type t :: %__MODULE__{query: String.t(), stacktrace: stacktrace() | nil}

    @enforce_keys [:query]
    defstruct [:query, :stacktrace]
  end

  defmodule QueryStats do
    @type t :: %__MODULE__{count: pos_integer(), time: pos_integer() | nil}
    defstruct [:count, :time]
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

  def report(by \\ :count) do
    with {:ok, by_fun} <- Map.fetch(@aggregate_mappings, by) do
      queries = Agent.get(__MODULE__, & &1.queries)

      {:ok,
       queries
       |> Enum.map(fn {query, queries} -> {query, by_fun.(queries)} end)
       |> Enum.sort_by(&elem(&1, 1), :desc)}
    else
      :error -> {:error, :invalid_sort_key}
    end
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

  def by_count(%QueryStats{count: count}) do
    count
  end

  def by_time(%QueryStats{time: time}) do
    time && System.convert_time_unit(time, :native, :millisecond)
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
