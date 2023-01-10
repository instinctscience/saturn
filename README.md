# Saturn

A child-eating monster; a library to help you find and eliminate N+1 queries.

## Usage

Once your application is configured to send Ecto telemetry events to Saturn (see below), you can query for the most-made queries:

```elixir
# Get ten most-made queries
Saturn.top_offenders(10)
#=>[
#=>  {%Saturn.Aggregator.Query{
#=>     query: "SELECT DISTINCT o0.\"queue\" FROM \"public\".\"oban_jobs\" AS o0 WHERE (o0.\"state\" = 'available') AND (NOT (o0.\"queue\" IS NULL))",
#=>     stacktrace: [
#=>       {Ecto.Repo.Supervisor, :tuplet, 2,
#=>        [file: 'lib/ecto/repo/supervisor.ex', line: 162]},
#=>       {MyApp.Repo, :all, 2, [file: 'lib/my_app/repo.ex', line: 2]},
#=>       {Oban.Plugins.Stager, :notify_queues, 1,
#=>        [file: 'lib/oban/plugins/stager.ex', line: 131]},
#=>       {Oban.Plugins.Stager, :"-check_leadership_and_stage/1-fun-0-", 1,
#=>        [file: 'lib/oban/plugins/stager.ex', line: 98]},
#=>       {Ecto.Adapters.SQL, :"-checkout_or_transaction/4-fun-0-", 3,
#=>        [file: 'lib/ecto/adapters/sql.ex', line: 1202]},
#=>       ...
#=>   }, 100},
#=>   ...
```

If you want to clear out all recorded queries, invoke `Saturn.clear/0`:

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
