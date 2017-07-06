defmodule Exbeans.Mixfile do
  use Mix.Project

  def project do
    [
      app: :exbeans,
      version: "0.1.0",
      elixir: "~> 1.4",
      start_permanent: Mix.env == :prod,
      deps: deps(),
      config_path: case Mix.env do :test -> "config/test.exs"; _ -> "config/config.exs" end
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :gen_state_machine],
      mod: {ExBeans, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_doc, "~> 0.14", only: :dev, runtime: false},
      {:mock, "~> 0.2.0", only: :test},
      {:gen_state_machine, "~> 2.0"}
    ]
  end
end
