import Config

if System.get_env("PHX_SERVER") do
  config :todoer_phoenix, TodoerPhoenixWeb.Endpoint, server: true
end

config :todoer_phoenix, TodoerPhoenixWeb.Endpoint,
  http: [port: String.to_integer(System.get_env("PORT", "4000"))]

if config_env() == :prod do
  database_url =
    System.get_env("DATABASE_URL") ||
      raise "DATABASE_URL is missing"

  config :todoer_phoenix, TodoerPhoenix.Repo,
    url: database_url,
    ssl: true,
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10")

  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise "SECRET_KEY_BASE is missing"

  host = System.get_env("PHX_HOST") || "example.com"

  config :todoer_phoenix, TodoerPhoenixWeb.Endpoint,
    server: true,
    url: [host: host, port: 443, scheme: "https"],
    http: [port: String.to_integer(System.get_env("PORT") || "4000")],
    check_origin: ["https://#{host}"],
    secret_key_base: secret_key_base
end
