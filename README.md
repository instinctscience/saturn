# Saturn

A child-eating monster; a library to help you find and eliminate N+1 queries.

## Usage

Once your application is configured to send Ecto telemetry events to Saturn (see below), you can query for the most-made queries:

```elixir
# Get ten most-made queries
Saturn.top_offenders(10)
```

If you want to clear out all recorded queries, invoke `Saturn.clear/0`:

```elixir
Saturn.clear()
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

That's it!  Next time your application starts, it should be sending Ecto telemetry events to Saturn for aggregation.
