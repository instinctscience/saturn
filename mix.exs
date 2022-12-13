defmodule Saturn.MixProject do
  use Mix.Project

  def project do
    [
      app: :saturn,
      version: "0.1.0",
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {Saturn.Application, []}
    ]
  end

  defp deps do
    [
      {:telemetry, "~> 1.1"}
    ]
  end

  defp aliases do
    [
      build: ["deps.get", "compile"]
    ]
  end
end
