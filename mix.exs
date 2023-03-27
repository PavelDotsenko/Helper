defmodule Helper.MixProject do
  use Mix.Project

  def project do
    [
      app: :helper,
      version: "1.0.0",
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: "Нескользо вспомогательных модулей для Elixir",
      package: package(),
      elixirc_paths: ["lib"],
      name: "Helper",
      source_url: "https://github.com/PavelDotsenko/Helper"
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp package do
    [
      files: ["lib", "mix.exs", "README.md", "LICENSE.md", ".gitignore", ".formatter.exs"],
      maintainers: ["Pavel Dotsenko", "Danil Farfudinov"],
      licenses: ["Apache 2.0"],
      links: %{
        GitHub: "https://github.com/PavelDotsenko/Helper",
        Issues: "https://github.com/PavelDotsenko/Helper/issues"
      }
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ecto_sql, "~> 3.6"},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end
end
