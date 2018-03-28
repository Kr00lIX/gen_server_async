defmodule GenServerAsync.Mixfile do
  use Mix.Project

  @version "0.0.1"

  def project do
    [
      app: :gen_server_async,
      version: @version,
      description: "GenServerAsync behaviour module for implementing the server of a client-server relation.",
      elixir: ">= 1.3.0",
      elixirc_paths: elixirc_paths(Mix.env()),
      package: package(),
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      deps: deps()
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
      {:ex_doc, ">= 0.0.0", only: :dev}
    ]
  end

  # Settings for publishing in Hex package manager:
  defp package do
    %{
      package: "gen_server_async",
      contributors: ["Kr00lIX"],
      maintainers: ["Anatoliy Kovalchuk"],
      links: %{github: "https://github.com/Kr00lIX/gen_server_async"},
      licenses: ["LISENSE.md"],
      files: ~w(lib LICENSE.md mix.exs README.md)
    }
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]
  
end
