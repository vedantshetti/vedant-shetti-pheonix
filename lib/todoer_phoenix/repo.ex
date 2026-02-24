defmodule TodoerPhoenix.Repo do
  use Ecto.Repo,
    otp_app: :todoer_phoenix,
    adapter: Ecto.Adapters.Postgres
end
