use Mix.Config

config :tesla, adapter: Tesla.Adapter.Hackney

if Mix.env() == :test, do: import_config("test.exs")
