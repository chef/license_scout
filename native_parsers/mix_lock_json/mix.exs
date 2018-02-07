defmodule MixLockJson.MixProject do
  use Mix.Project

  def project do
    [
      app: :mix_lock_json,
      version: "0.1.0",
      escript: escript(),
      deps: deps()
    ]
  end

  def application do
    [applications: []]
  end

  defp escript do
    [
      main_module: MixLockJson.CLI,
      path: "../../bin/mix_lock_json",
      app: nil,
      embed_elixir: true
    ]
  end

  defp deps do
    [
      {:poison, "~> 3.1"}
    ]
  end
end
