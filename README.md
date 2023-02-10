# Saturn

A child-eating monster; a library to help you find and eliminate N+1 queries.

## Usage

Once your application is configured to send Ecto telemetry events to Saturn (see below), you can query for the most-made queries:

```elixir
iex> Saturn.report()
Query: "SELECT DISTINCT o0.\"queue\" FROM \"public\".\"oban_jobs\" AS o0 WHERE (o0.\"state\" = 'available') AND (NOT (o0.\"queue\" IS NULL))"
Count: 100
Stacktrace:
  lib/ecto/repo/supervisor.ex:162: Ecto.Repo.Supervisor.tuplet/2
  lib/my_app/repo.ex:2: MyApp.Repo.all/2
  lib/oban/plugins/stager.ex:131: Oban.Plugins.Stager.notify_queues/1
  lib/oban/plugins/stager.ex:98: Oban.Plugins.Stager.-check_leadership_and_stage/1-fun-0-/1
  lib/ecto/adapters/sql.ex:1202: Ecto.Adapters.SQL.-checkout_or_transaction/4-fun-0-/3
  ...
#=> :ok
```

The return format is `{query, count}` where `query` contains the query text as well as the stacktrace and `count` is the number of times the query was made.

Saturn also supports querying by time:

```elixir
iex> Saturn.report(:time)
Query: "SELECT DISTINCT o0.\"queue\" FROM \"public\".\"oban_jobs\" AS o0 WHERE (o0.\"state\" = 'available') AND (NOT (o0.\"queue\" IS NULL))"
Time: 157 ms
Stacktrace:
  lib/ecto/repo/supervisor.ex:162: Ecto.Repo.Supervisor.tuplet/2
  lib/my_app/repo.ex:2: MyApp.Repo.all/2
  lib/oban/plugins/stager.ex:131: Oban.Plugins.Stager.notify_queues/1
  lib/oban/plugins/stager.ex:98: Oban.Plugins.Stager.-check_leadership_and_stage/1-fun-0-/1
  lib/ecto/adapters/sql.ex:1202: Ecto.Adapters.SQL.-checkout_or_transaction/4-fun-0-/3
  ...
#=> :ok
```

Lastly, Saturn supports a prof-style output (a la `eprof`, `fprof`, etc) to help you identify cost centers:

```elixir
iex> Saturn.report(:prof)
Source                                                                   Count %Count     Time %Time
Saturn.fake/1                                                                2     66   246.91    95
  SELECT * FROM users;                                                       2     66   246.91    95
Saturn.foobar/2                                                              1     33    12.35     4
  Saturn.Foobar.do_thing/3                                                   1     33    12.35     4
    SELECT * FROM users WHERE id = 5;                                        1     33    12.35     4
```


If you want to clear all recorded queries, invoke `Saturn.clear/0`:

```elixir
Saturn.clear()
#=> :ok
```

## Installation

The package can be installed by adding `saturn` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:saturn, git: "git@github.com:instinctscience/saturn.git"}
  ]
end
```

First, your application needs to be configured to send Ecto telemetry events to Saturn:

```elixir
# lib/myapp_web/telemetry.ex

:ok =
  :telemetry.attach(
    "saturn-aggregator",
    [:myapp, :repo, :query],
    &Saturn.handle_query/4,
    nil
  )
```

Next, in order for Saturn to collect and report stacktraces, Ecto needs to be configured to include stacktraces in its telemetry events:

```elixir
# config/dev.exs

config :myapp, :repo,
  username: "postgres",
  password: "postgres",
  # etc
  stacktrace: true
```

By default, Saturn starts disabled (i.e. not collecting query data) to save memory.  When you'd like to start collecting query data, run:

```elixir
Saturn.enable()
```

To disable Saturn again, run:

```elixir
Saturn.disable()
```

You can also configure Saturn to be enabled at start-up using the `enable` key of its configuration:

```elixir
config :saturn, enable: true
```

That's it!  Next time your application starts, it should send Ecto telemetry events to Saturn for aggregation.
