defmodule Mix.Tasks.Saturn.Analyze do
  @moduledoc "Scan the codebase for suspected N+1 queries"
  use Mix.Task

  alias __MODULE__.Aggregator

  @shortdoc "Scan the codebase for suspected N+1 queries"
  @impl Mix.Task
  def run(args) do
    do_run(args)
  end

  def main(_), do: run([])

  defp do_run(opts) do
    {:ok, _} = Aggregator.start_link()
    # Code.put_compiler_option(:parser_options, columns: true)
    Code.put_compiler_option(:tracers, [Aggregator])
    Mix.Task.run("compile", ["--force"])
    Aggregator.export(opts)
  end

  defmodule Aggregator do
    @moduledoc false
    use Agent

    def start_link() do
      Agent.start_link(&init/0, name: __MODULE__)
    end

    def init() do
      []
    end

    def trace({:remote_function, meta, module, name, arity}, env) do
      IO.inspect(meta, label: "META")
      IO.inspect({module, name, arity})

      IO.inspect(%Macro.Env{env | functions: [], macros: []},
        structs: false,
        limit: :infinity,
        printable_limit: :infinity
      )

      :ok
    end

    def trace(_event, _env) do
      :ok
    end

    def export(_opts) do
      :ok
    end
  end
end
