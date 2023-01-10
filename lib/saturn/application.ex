defmodule Saturn.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {Saturn.Aggregator, Application.get_all_env(:saturn)}
    ]

    opts = [strategy: :one_for_one, name: Saturn.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
