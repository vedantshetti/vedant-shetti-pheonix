defmodule TodoerPhoenix.Todos.Todo do
  use Ecto.Schema
  import Ecto.Changeset

  schema "todos" do
    field(:title, :string)
    field(:description, :string)

    field(:status, Ecto.Enum,
      values: [:"in-progress", :"on-hold", :completed],
      default: :"in-progress"
    )

    field(:sequence, :integer, default: 1)
    field(:bookmarked, :boolean, default: false)
    field(:category, :string)

    belongs_to(:user, TodoerPhoenix.Accounts.User)
    has_many(:subtasks, TodoerPhoenix.Todos.Subtask, preload_order: [asc: :sequence])

    timestamps(type: :naive_datetime, inserted_at: :created_at, updated_at: false)
  end

  def changeset(todo, attrs) do
    todo
    |> cast(attrs, [:title, :description, :status, :sequence, :bookmarked, :category, :user_id])
    |> validate_required([:title, :user_id])
  end
end
