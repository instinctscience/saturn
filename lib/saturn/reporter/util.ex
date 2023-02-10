defmodule Saturn.Reporter.Util do
  @moduledoc false

  # Just a collection of functions that are used by more than one reporter.

  @spec format_mfa({module, atom, pos_integer}) :: String.t()
  def format_mfa({mod, fun, arity}) do
    "#{String.replace_prefix(to_string(mod), "Elixir.", "")}.#{fun}/#{arity}"
  end

  @spec format_stacktrace([{module, atom, pos_integer, [file: String.t(), line: pos_integer]}]) ::
          String.t()
  def format_stacktrace(stacktrace) do
    lines =
      stacktrace
      |> Enum.map(fn {mod, fun, arity, [file: f, line: l]} ->
        "  #{f}:#{l}: #{format_mfa({mod, fun, arity})}"
      end)
      |> Enum.join("\n")

    "Stacktrace:\n" <> lines
  end
end
