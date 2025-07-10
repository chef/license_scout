defmodule InchTest.Mixfile do
  use Mix.Project

  def project do
    [app: :inch_test,
     version: "0.0.1",
     elixir: "~> 1.0-dev",
     docs: [main: "README", readme: true],
     deps: deps(),
     escript: [main_module: MixLockJson.CLI]]
  end

  # Configuration for the OTP application
  #
  # Type `mix help compile.app` for more information
  def application do
  [applications: [:logger, :poison, :jason]]
end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type `mix help deps` for more examples and options
  defp deps do
    [{:ex_doc, "~> 0.6"},
     {:earmark, ">= 0.0.0"},
     {:inch_ex, "~> 2.0", only: :docs},
     {:poison, "~> 5.0"},
     {:jason, "~> 1.4"}]
  end
end
