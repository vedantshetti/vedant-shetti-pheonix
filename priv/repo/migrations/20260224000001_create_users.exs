defmodule TodoerPhoenix.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def up do
    execute("CREATE TABLE IF NOT EXISTS users (
      id SERIAL PRIMARY KEY,
      name TEXT NOT NULL,
      email TEXT NOT NULL UNIQUE,
      password TEXT NOT NULL,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )")
  end

  def down do
    drop_if_exists(table(:users))
  end
end
