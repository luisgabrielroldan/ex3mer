defmodule Ex3mer.MixProject do
  use Mix.Project

  @version "0.1.0"
  @source_url "https://github.com/luisgabrielroldan/ex3mer"

  def project do
    [
      app: :ex3mer,
      version: @version,
      elixir: "~> 1.8",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      docs: docs(),
      dialyzer: dialyzer()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp docs do
    [
      main: "readme",
      source_ref: "v#{@version}",
      source_url: @source_url,
      extras: ["README.md"]
    ]
  end

  defp dialyzer do
    [
      plt_add_deps: :apps_direct,
      flags: [:unmatched_returns, :error_handling, :race_conditions, :no_opaque]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:dialyxir, "~> 1.0", only: [:dev], runtime: false},
      {:ex_aws, "~> 2.0"},
      {:ex_aws_s3, "~> 2.0"},
      {:hackney, "~> 1.9"},
      {:httpoison, "~> 1.6"},
      {:mox, "~> 1.0", only: [:test]},
      {:poison, "~> 3.0"},
      {:sweet_xml, "~> 0.6.6"}
    ]
  end
end
