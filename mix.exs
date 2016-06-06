defmodule Camera.Mixfile do
  use Mix.Project

  def project do
    [app: :camera,
     version: "0.0.1",
     elixir: "~> 1.3-dev",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [applications: [:logger]]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [{:phoenix, "~> 1.2.0-rc.0"},
     {:phoenix_pubsub, "~> 1.0.0-rc"},
     {:postgrex, ">= 0.0.0"},
     {:phoenix_ecto, "~> 3.0.0-rc"},
     {:ecto, "~> 2.0.0-rc.5", override: true},
     {:phoenix_html, "~> 2.4"},
     {:phoenix_live_reload, "~> 1.0", only: :dev},
     {:gettext, "~> 0.9"},
     {:cowboy, "~> 1.0"}
     ]
  end
end
