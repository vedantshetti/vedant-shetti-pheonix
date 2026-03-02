import Config

config :todoer_phoenix, TodoerPhoenixWeb.Endpoint,
  cache_static_manifest: "priv/static/cache_manifest.json"

config :logger, level: :info
