defmodule Saturn.Aggregator do
  use Agent
  require Logger

  defmodule Query do
    defstruct [:query, stacktrace: nil]
  end

  # measurements:
  # %{decode_time: 5950, idle_time: 1199657146, query_time: 111592975, queue_time: 863357, total_time: 112462282}
  # %{decode_time: 2600, query_time: 123814, total_time: 126414}
  # %{query_time: 144045, total_time: 144045}
  def handle_query(
        [_app, :repo, :query],
        _measurements,
        %{query: query} = metadata,
        _config
      ) do
    add_query(%Query{query: query, stacktrace: Map.get(metadata, :stacktrace)})
  end

  def top_offenders(num) do
    queries = Agent.get(__MODULE__, &Function.identity/1)

    queries
    |> Enum.sort_by(fn {_query, count} -> count end, :desc)
    |> Enum.take(num)
  end

  def clear() do
    Agent.update(__MODULE__, fn _ -> %{} end)
  end

  defp add_query(query) do
    Agent.update(__MODULE__, fn state -> Map.update(state, query, 1, &(&1 + 1)) end)
  end

  def start_link(_) do
    Agent.start_link(fn -> %{} end, name: __MODULE__)
  end
end
