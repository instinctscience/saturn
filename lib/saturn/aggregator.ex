defmodule Saturn.Aggregator do
  use Agent

  defmodule State do
    @type t :: %__MODULE__{
            enabled: boolean(),
            queries: %{Saturn.Aggregator.Query.t() => pos_integer()}
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

  def report() do
    queries = Agent.get(__MODULE__, & &1.queries)

    Enum.sort_by(queries, fn {_query, count} -> count end, :desc)
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

  defp add_query(query) do
    if Agent.get(__MODULE__, & &1.enabled) do
      Agent.update(__MODULE__, fn state = %{queries: queries} ->
        %State{state | queries: Map.update(queries, query, 1, &(&1 + 1))}
      end)
    end
  end

  def start_link(opts) do
    enabled = Keyword.get(opts, :enable, false)
    Agent.start_link(fn -> %State{enabled: enabled} end, name: __MODULE__)
  end
end
