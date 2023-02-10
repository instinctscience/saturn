defmodule Saturn.Reporter.Prof do
  @behaviour Saturn.Reporter
  import Saturn.Reporter.Util

  defmodule Stats do
    @type t :: %__MODULE__{
            cumulative_count: pos_integer(),
            percent_count: pos_integer(),
            cumulative_time: pos_integer(),
            percent_time: pos_integer()
          }

    defstruct cumulative_count: 0, cumulative_time: 0, percent_count: 0, percent_time: 0
  end

  defmodule Node do
    @moduledoc false

    # A node represents a function.  A function can have queries (issued
    # directly from its body) and children (functions called from its body).  We
    # also compute stats which are an accumulation of the stats from its queries
    # and children.

    alias Saturn.Reporter.Prof.Stats

    @type t :: %__MODULE__{
            queries: %{String.t() => Stats.t()},
            children: %{String.t() => t()},
            stats: Stats.t()
          }
    defstruct queries: %{},
              children: %{},
              stats: %Stats{}
  end

  @impl Saturn.Reporter
  def report(queries) do
    queries
    |> build_tree()
    |> format_tree()
  end

  def build_tree(queries) do
    queries
    |> Enum.reduce(%Node{}, fn {query, query_stats}, root ->
      path =
        query.stacktrace
        |> List.wrap()
        |> remove_metadata()
        |> Enum.reverse()

      put_in_node(root, path, {query.query, query_stats})
    end)
    |> compute_cumulatives()
    |> compute_percentages()
  end

  defp put_in_node(node, [], {query, query_stats}) do
    %Node{node | queries: Map.put(node.queries, query, convert_stats(query_stats))}
  end

  defp put_in_node(node, [fst | rest], value) do
    new_child = put_in_node(Map.get(node.children, fst, %Node{}), rest, value)
    %Node{node | children: Map.put(node.children, fst, new_child)}
  end

  defp convert_stats(%Saturn.QueryStats{count: count, time: time}) do
    %Stats{cumulative_count: count, cumulative_time: time}
  end

  defp compute_cumulatives(node) do
    computed_children = transform_values(node.children, &compute_cumulatives/1)

    direct_stats = Enum.map(node.queries, &elem(&1, 1))
    child_stats = computed_children |> Map.values() |> Enum.map(& &1.stats)
    all_stats = direct_stats ++ child_stats

    stats = %Stats{
      node.stats
      | cumulative_time: Enum.sum(Enum.map(all_stats, &(&1.cumulative_time || 0))),
        cumulative_count: Enum.sum(Enum.map(all_stats, & &1.cumulative_count))
    }

    %Node{node | stats: stats, children: computed_children}
  end

  # This handles the root node; all child nodes are handled by the unfortunately
  # named `do_compute_percentages'.
  defp compute_percentages(
         %Node{
           children: children,
           queries: queries,
           stats: %Stats{cumulative_count: total_count, cumulative_time: total_time} = stats
         } = node
       ) do
    %Node{
      node
      | children:
          transform_values(children, &do_compute_percentages(&1, total_count, total_time)),
        queries: transform_values(queries, &do_compute_percentages(&1, total_count, total_time)),
        stats: %Stats{stats | percent_count: 100, percent_time: 100}
    }
  end

  defp do_compute_percentages(
         %Node{children: children, queries: queries, stats: stats} = node,
         total_count,
         total_time
       ) do
    %Node{
      node
      | children:
          transform_values(children, &do_compute_percentages(&1, total_count, total_time)),
        queries: transform_values(queries, &do_compute_percentages(&1, total_count, total_time)),
        stats: do_compute_percentages(stats, total_count, total_time)
    }
  end

  defp do_compute_percentages(
         %Stats{cumulative_count: count, cumulative_time: time} = stats,
         total_count,
         total_time
       ) do
    %Stats{
      stats
      | percent_count: percent_of(count, total_count),
        percent_time: percent_of(time, total_time)
    }
  end

  defp percent_of(numerator, denominator) do
    div(numerator * 100, denominator)
  end

  defp remove_metadata(stacktrace) do
    Enum.map(stacktrace, &Tuple.delete_at(&1, 3))
  end

  # I don't like it either
  defp transform_values(map, fun) do
    :maps.map(fn _k, v -> fun.(v) end, map)
  end

  def format_tree(tree) do
    header =
      "Source                                                                   Count %Count     Time %Time"

    body = Map.merge(tree.queries, tree.children) |> format_body("")

    header <> "\n" <> body
  end

  defp format_node(name, node, prefix) do
    node_line = format_row(name, node.stats, prefix)
    child_prefix = prefix <> "  "

    body = Map.merge(node.queries, node.children) |> format_body(child_prefix)

    node_line <> "\n" <> body
  end

  defp format_body(all_children, child_prefix) do
    all_children
    # TODO: make this sort configurable
    |> Enum.sort_by(
      fn
        {_name, %Node{stats: %Stats{cumulative_time: time}}} -> time
        {_query, %Stats{cumulative_time: time}} -> time
      end,
      :desc
    )
    |> Enum.map(fn {id, node_or_stats} -> format_item(id, node_or_stats, child_prefix) end)
    |> Enum.join("\n")
  end

  defp format_item(name, node, prefix) when is_struct(node, Node),
    do: format_node(name, node, prefix)

  defp format_item(name, stats, prefix), do: format_row(name, stats, prefix)

  defp format_row(name, stats, prefix) do
    prefix = "#{prefix}#{format_name(name)}" |> String.slice(0, 72) |> String.pad_trailing(73)
    count_str = String.pad_leading(to_string(stats.cumulative_count), 5)
    count_per_str = String.pad_leading(to_string(stats.percent_count), 7)

    time_str =
      stats.cumulative_time
      |> System.convert_time_unit(:native, :millisecond)
      |> Kernel./(1000)
      |> Float.round(2)
      |> to_string()
      |> String.pad_leading(9)

    time_per_str = String.pad_leading(to_string(stats.percent_time), 6)

    Enum.join([prefix, count_str, count_per_str, time_str, time_per_str])
  end

  defp format_name({mod, fun, arity}) do
    format_mfa({mod, fun, arity})
  end

  defp format_name(str) do
    String.replace(str, ~r/\s+/, " ")
  end
end
