defmodule TodoerPhoenix.Repo.Migrations.CreateTodosAndSubtasks do
  use Ecto.Migration

  def up do
    execute("DO $$ BEGIN
      CREATE TYPE todo_status AS ENUM ('in-progress', 'on-hold', 'completed');
    EXCEPTION WHEN duplicate_object THEN null;
    END $$;")

    execute("CREATE TABLE IF NOT EXISTS todos (
      id SERIAL PRIMARY KEY,
      title TEXT NOT NULL,
      description TEXT,
      status todo_status NOT NULL DEFAULT 'in-progress',
      sequence INTEGER NOT NULL DEFAULT 1,
      user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
      bookmarked BOOLEAN NOT NULL DEFAULT FALSE,
      category TEXT,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );")

    execute("CREATE TABLE IF NOT EXISTS subtasks (
      id SERIAL PRIMARY KEY,
      todo_id INTEGER NOT NULL REFERENCES todos(id) ON DELETE CASCADE,
      title TEXT NOT NULL,
      completed BOOLEAN NOT NULL DEFAULT FALSE,
      sequence INTEGER NOT NULL DEFAULT 1,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );")
  end

  def down do
    execute("DROP TABLE IF EXISTS subtasks;")
    execute("DROP TABLE IF EXISTS todos;")
    execute("DROP TYPE IF EXISTS todo_status;")
  end
end
