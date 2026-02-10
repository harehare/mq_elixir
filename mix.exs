defmodule Mq.MixProject do
  use Mix.Project

  @version "0.1.2"
  @source_url "https://github.com/harehare/mq_elixir"

  def project do
    [
      app: :mq_elixir,
      version: @version,
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      package: package(),
      docs: docs(),
      test_coverage: [tool: ExCoveralls]
    ]
  end

  def cli do
    [
      preferred_envs: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:rustler, "~> 0.37.0"},
      {:ex_doc, "~> 0.31", only: :dev, runtime: false},
      {:excoveralls, "~> 0.18", only: :test},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false}
    ]
  end

  defp description do
    """
    Elixir bindings for mq, a jq-like command-line tool for Markdown processing.
    Process markdown, MDX, HTML, and plain text using the mq query language.
    """
  end

  defp package do
    [
      name: "mq_elixir",
      files:
        ~w(lib native/mq_nif/src native/mq_nif/Cargo.toml native/mq_nif/Cargo.lock .formatter.exs mix.exs README.md LICENSE CHANGELOG.md),
      licenses: ["MIT"],
      links: %{
        "GitHub" => @source_url,
        "Documentation" => "https://mqlang.org/"
      },
      maintainers: ["Takahiro Sato"]
    ]
  end

  defp docs do
    [
      main: "Mq",
      source_ref: "v#{@version}",
      source_url: @source_url,
      extras: ["README.md", "CHANGELOG.md"]
    ]
  end
end
