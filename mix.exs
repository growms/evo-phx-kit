defmodule EvoPhxKit.MixProject do
  use Mix.Project

  def project do
    [
      app: :evo_phx_kit,
      version: "0.1.0",
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      elixirc_paths: elixirc_paths(Mix.env())
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:plug, "~> 1.16"},
      {:phoenix_live_view, "~> 1.0"},
      {:gettext, ">= 0.26.0"},
      {:jason, "~> 1.4"},
      {:igniter, "~> 0.5", optional: true}
    ]
  end
end
