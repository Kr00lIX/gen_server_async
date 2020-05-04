defmodule GenServerAsync.Mixfile do
  use Mix.Project

  @version "0.0.3"

  def project do
    [
      app: :gen_server_async,
      version: @version,
      elixir: ">= 1.4.0",
      elixirc_paths: elixirc_paths(Mix.env()),
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      deps: deps(),

      # Hex
      description:
        "GenServerAsync behaviour module for implementing the server of a client-server relation.",
      package: package(),

      # Test
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [coveralls: :test, "coveralls.travis": :test],

      # Docs
      name: "GenServerAsync",
      docs: docs(),

      # Dev
      dialyzer: [flags: ["-Wunmatched_returns", :error_handling, :underspecs]]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Type "mix help deps" for more examples and options
  defp deps do
    [
      # Test
      {:excoveralls, "~> 0.10", only: :test},
      {:junit_formatter, "~> 3.0", only: :test},
      {:credo, "~> 1.0", only: [:dev, :test]},

      # Dev
      {:dialyxir, "~> 1.0.0-rc.6", only: :dev, runtime: false},
      {:ex_doc, "~> 0.19", only: :dev, runtime: false},
      {:inch_ex, ">= 0.0.0", only: :dev}
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

  defp docs do
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
