defmodule TodoerPhoenix.Todos do
  import Ecto.Query
  alias TodoerPhoenix.Repo
  alias TodoerPhoenix.Todos.{Todo, Subtask}

  def list_todos(user_id, opts \\ []) do
    page = max(1, opts[:page] || 1)
    limit = min(100, max(1, opts[:limit] || 10))
    offset = (page - 1) * limit
    status = opts[:status] || "all"
    search = opts[:search] || ""
    category = opts[:category] || ""
    bookmarked = opts[:bookmarked] || false

    base =
      from(t in Todo,
        where: t.user_id == ^user_id
      )

    base =
      if status != "all",
        do: where(base, [t], t.status == ^String.to_existing_atom(status)),
        else: base

    base =
      if search != "",
        do:
          where(base, [t], ilike(t.title, ^"%#{search}%") or ilike(t.description, ^"%#{search}%")),
        else: base

    base = if category != "", do: where(base, [t], t.category == ^category), else: base
    base = if bookmarked, do: where(base, [t], t.bookmarked == true), else: base

    total = Repo.aggregate(base, :count, :id)

    todos =
      base
      |> order_by([t], asc: t.sequence)
      |> limit(^limit)
      |> offset(^offset)
      |> Repo.all()
      |> Repo.preload(subtasks: from(s in Subtask, order_by: [asc: s.sequence]))

    %{
      todos: todos,
      pagination: %{
        total: total,
        page: page,
        limit: limit,
        total_pages: max(1, ceil(total / limit))
      }
    }
  end

  def list_categories(user_id) do
    Repo.all(
      from(t in Todo,
        where: t.user_id == ^user_id and not is_nil(t.category) and t.category != "",
        distinct: true,
        select: t.category,
        order_by: t.category
      )
    )
  end

  def create_todo(user_id, attrs) do
    max_seq =
      Repo.one(from(t in Todo, where: t.user_id == ^user_id, select: max(t.sequence))) || 0

    %Todo{}
    |> Todo.changeset(Map.merge(attrs, %{"user_id" => user_id, "sequence" => max_seq + 1}))
    |> Repo.insert()
  end

  def update_todo(id, user_id, attrs) do
    case Repo.get_by(Todo, id: id, user_id: user_id) do
      nil -> {:error, :not_found}
      todo -> todo |> Todo.changeset(attrs) |> Repo.update()
    end
  end

  def delete_todo(id, user_id) do
    case Repo.get_by(Todo, id: id, user_id: user_id) do
      nil -> {:error, :not_found}
      todo -> Repo.delete(todo)
    end
  end

  def bulk_delete_todos(ids, user_id) do
    Repo.delete_all(from(t in Todo, where: t.id in ^ids and t.user_id == ^user_id))
  end

  def toggle_bookmark(id, user_id) do
    case Repo.get_by(Todo, id: id, user_id: user_id) do
      nil -> {:error, :not_found}
      todo -> todo |> Todo.changeset(%{"bookmarked" => !todo.bookmarked}) |> Repo.update()
    end
  end

  def reorder_todos(ordered_ids, user_id) do
    ordered_ids
    |> Enum.with_index(1)
    |> Enum.each(fn {id, seq} ->
      Repo.update_all(
        from(t in Todo, where: t.id == ^id and t.user_id == ^user_id),
        set: [sequence: seq]
      )
    end)

    :ok
  end

  defp owns_todo?(todo_id, user_id) do
    Repo.exists?(from(t in Todo, where: t.id == ^todo_id and t.user_id == ^user_id))
  end

  def list_subtasks(todo_id, user_id) do
    if owns_todo?(todo_id, user_id) do
      {:ok,
       Repo.all(from(s in Subtask, where: s.todo_id == ^todo_id, order_by: [asc: s.sequence]))}
    else
      {:error, :forbidden}
    end
  end

  def create_subtask(todo_id, user_id, title) do
    if owns_todo?(todo_id, user_id) do
      max_seq =
        Repo.one(from(s in Subtask, where: s.todo_id == ^todo_id, select: max(s.sequence))) || 0

      %Subtask{}
      |> Subtask.changeset(%{"todo_id" => todo_id, "title" => title, "sequence" => max_seq + 1})
      |> Repo.insert()
    else
      {:error, :forbidden}
    end
  end

  def update_subtask(subtask_id, todo_id, user_id, attrs) do
    if owns_todo?(todo_id, user_id) do
      case Repo.get_by(Subtask, id: subtask_id, todo_id: todo_id) do
        nil -> {:error, :not_found}
        s -> s |> Subtask.changeset(attrs) |> Repo.update()
      end
    else
      {:error, :forbidden}
    end
  end

  def delete_subtask(subtask_id, todo_id, user_id) do
    if owns_todo?(todo_id, user_id) do
      case Repo.get_by(Subtask, id: subtask_id, todo_id: todo_id) do
        nil -> {:error, :not_found}
        s -> Repo.delete(s)
      end
    else
      {:error, :forbidden}
    end
  end

  def get_todo(id, user_id) do
    case Repo.get_by(Todo, id: id, user_id: user_id) do
      nil -> nil
      todo -> Repo.preload(todo, subtasks: from(s in Subtask, order_by: [asc: s.sequence]))
    end
  end
end
