defmodule TodoerPhoenix.Todos.Subtask do
  use Ecto.Schema
  import Ecto.Changeset

  schema "subtasks" do
    field(:title, :string)
    field(:completed, :boolean, default: false)
    field(:sequence, :integer, default: 1)

    belongs_to(:todo, TodoerPhoenix.Todos.Todo)

    timestamps(type: :naive_datetime, inserted_at: :created_at, updated_at: false)
  end

  def changeset(subtask, attrs) do
    subtask
    |> cast(attrs, [:title, :completed, :sequence, :todo_id])
    |> validate_required([:title, :todo_id])
  end
end
