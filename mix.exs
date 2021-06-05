defmodule Ex3mer.MixProject do
  use Mix.Project

  @app_name :ex3mer
  @version "0.1.0"
  @github "https://github.com/luisgabrielroldan/ex3mer"

  def project do
    [
      app: @app_name,
      version: @version,
      elixir: "~> 1.8",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      dialyzer: dialyzer(),
      description: description(),
      package: package(),
      docs: docs(),
      source_url: @github
    ]
  end

  def description do
    """
    Ex3mer is a library for building streams from HTTP resources
    """
  end

  defp package do
    %{
      name: @app_name,
      maintainers: ["Gabriel Roldan"],
      licenses: ["Apache License 2.0"],
      links: %{"GitHub" => @github},
      files: [
        "lib",
        "mix.exs",
        "README.md"
      ]
    }
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
      source_url: @github,
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
      {:ex_doc, ">= 0.0.0", only: :dev},
      {:dialyxir, "~> 1.0", only: :dev, runtime: false},
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
