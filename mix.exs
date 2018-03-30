defmodule GenServerAsync.Mixfile do
  use Mix.Project

  @version "0.0.2"

  def project do
    [
      app: :gen_server_async,
      version: @version,
      elixir: "~> 1.4",
      elixirc_paths: elixirc_paths(Mix.env()),
      build_per_environment: false,
      deps: deps(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: ["coveralls": :test, "coveralls.travis": :test],

      # Hex
      description: "GenServerAsync behaviour module for implementing the server of a client-server relation.",
      package: package(),

      # Docs
      name: "GenServerAsync",
      docs: docs()  
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
    ]
  end

  # Type "mix help deps" for more examples and options
  defp deps do
    [
      {:excoveralls, "~> 0.8", only: :test},

      # Docs
      {:ex_doc, "~> 0.17", only: :docs},
      {:inch_ex, ">= 0.0.0", only: :docs}
    ]
  end

  # Settings for publishing in Hex package manager:
  defp package do
    %{
      package: "gen_server_async",
      contributors: ["Kr00lIX"],
      maintainers: ["Anatoliy Kovalchuk"],
      links: %{github: "https://github.com/Kr00lIX/gen_server_async"},
      licenses: ["LICENSE.md"],
      files: ~w(lib LICENSE.md mix.exs README.md)
    }
  end

  def docs do
    [
      main: "GenServerAsync",
      source_ref: "v#{@version}",
      extras: ["README.md"],
      source_url: "https://github.com/Kr00lIX/gen_server_async"
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]
  
end
