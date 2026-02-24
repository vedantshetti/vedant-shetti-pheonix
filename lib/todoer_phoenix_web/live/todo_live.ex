defmodule TodoerPhoenixWeb.TodoLive do
  use TodoerPhoenixWeb, :live_view
  alias TodoerPhoenix.Todos

  @impl true
  def mount(_params, _session, socket) do
    # User is passed from client-side sessionStorage via connect_params
    raw_user = get_connect_params(socket)["user"]

    user =
      case raw_user do
        %{"id" => id, "name" => name, "email" => email} ->
          %{id: id, name: name, email: email}

        _ ->
          nil
      end

    if is_nil(user) do
      {:ok, push_navigate(socket, to: "/login")}
    else
      result = Todos.list_todos(user.id, [])
      categories = Todos.list_categories(user.id)

      {:ok,
       socket
       |> assign(:current_user, user)
       |> assign(:todos, result.todos)
       |> assign(:pagination, result.pagination)
       |> assign(:categories, categories)
       |> assign(:selected_todos, [])
       |> assign(:filter_status, "all")
       |> assign(:search, "")
       |> assign(:filter_category, "")
       |> assign(:bookmarked_only, false)
       |> assign(:current_page, 1)
       |> assign(:items_per_page, 10)
       |> assign(:delete_todo, nil)
       |> assign(:subtask_todo, nil)
       |> assign(:new_title, "")
       |> assign(:new_description, "")
       |> assign(:new_category, "")
       |> assign(:new_custom_category, "")
       |> assign(:show_extra, false)
       |> assign(:new_subtask_title, "")
       |> assign(:edit_todo_id, nil)
       |> assign(:edit_title, "")
       |> assign(:edit_description, "")
       |> assign(:edit_category, "")}
    end
  end

  defp load_todos(socket) do
    user_id = socket.assigns.current_user.id

    opts = [
      page: socket.assigns.current_page,
      limit: socket.assigns.items_per_page,
      status: socket.assigns.filter_status,
      search: socket.assigns.search,
      category: socket.assigns.filter_category,
      bookmarked: socket.assigns.bookmarked_only
    ]

    result = Todos.list_todos(user_id, opts)
    categories = Todos.list_categories(user_id)

    socket
    |> assign(:todos, result.todos)
    |> assign(:pagination, result.pagination)
    |> assign(:categories, categories)
  end

  # ── Events ────────────────────────────────────────────────────────────────────

  @impl true
  def handle_event("logout", _params, socket) do
    {:noreply, push_navigate(socket, to: "/login")}
  end

  # ─── Add Todo ──────────────────────────────────────────────────────────────

  @impl true
  def handle_event("add_todo", %{"title" => title} = params, socket) do
    title = String.trim(title)

    if title == "" do
      {:noreply, socket}
    else
      cat = String.trim(params["custom_category"] || "")
      cat = if cat == "", do: String.trim(params["category"] || ""), else: cat
      cat = if cat == "", do: nil, else: cat

      Todos.create_todo(socket.assigns.current_user.id, %{
        "title" => title,
        "description" =>
          String.trim(params["description"] || "") |> then(&if &1 == "", do: nil, else: &1),
        "category" => cat
      })

      {:noreply,
       socket
       |> assign(:new_title, "")
       |> assign(:new_description, "")
       |> assign(:new_category, "")
       |> assign(:new_custom_category, "")
       |> assign(:show_extra, false)
       |> load_todos()}
    end
  end

  @impl true
  def handle_event("toggle_extra", _, socket) do
    {:noreply, assign(socket, :show_extra, !socket.assigns.show_extra)}
  end

  # ─── Update Todo fields inline ─────────────────────────────────────────────

  @impl true
  def handle_event("change_status", %{"id" => id, "status" => status}, socket) do
    Todos.update_todo(String.to_integer(id), socket.assigns.current_user.id, %{"status" => status})

    {:noreply, load_todos(socket)}
  end

  @impl true
  def handle_event("toggle_bookmark", %{"id" => id}, socket) do
    Todos.toggle_bookmark(String.to_integer(id), socket.assigns.current_user.id)
    {:noreply, load_todos(socket)}
  end

  @impl true
  def handle_event("start_edit", %{"id" => id}, socket) do
    todo = Enum.find(socket.assigns.todos, &(to_string(&1.id) == id))

    if todo do
      {:noreply,
       socket
       |> assign(:edit_todo_id, todo.id)
       |> assign(:edit_title, todo.title)
       |> assign(:edit_description, todo.description || "")
       |> assign(:edit_category, todo.category || "")}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("cancel_edit", _, socket) do
    {:noreply, assign(socket, :edit_todo_id, nil)}
  end

  @impl true
  def handle_event(
        "save_edit",
        %{"title" => title, "description" => desc, "category" => cat},
        socket
      ) do
    id = socket.assigns.edit_todo_id
    cat = if String.trim(cat) == "", do: nil, else: String.trim(cat)

    Todos.update_todo(id, socket.assigns.current_user.id, %{
      "title" => String.trim(title),
      "description" => String.trim(desc) |> then(&if &1 == "", do: nil, else: &1),
      "category" => cat
    })

    {:noreply, socket |> assign(:edit_todo_id, nil) |> load_todos()}
  end

  # ─── Delete ────────────────────────────────────────────────────────────────

  @impl true
  def handle_event("confirm_delete", %{"id" => id}, socket) do
    todo = Enum.find(socket.assigns.todos, &(to_string(&1.id) == id))
    {:noreply, assign(socket, :delete_todo, todo)}
  end

  @impl true
  def handle_event("cancel_delete", _, socket) do
    {:noreply, assign(socket, :delete_todo, nil)}
  end

  @impl true
  def handle_event("do_delete", _, socket) do
    todo = socket.assigns.delete_todo
    Todos.delete_todo(todo.id, socket.assigns.current_user.id)
    {:noreply, socket |> assign(:delete_todo, nil) |> assign(:current_page, 1) |> load_todos()}
  end

  # ─── Selection & Bulk ─────────────────────────────────────────────────────

  @impl true
  def handle_event("select_todo", %{"id" => id}, socket) do
    id = String.to_integer(id)
    selected = socket.assigns.selected_todos
    selected = if id in selected, do: List.delete(selected, id), else: [id | selected]
    {:noreply, assign(socket, :selected_todos, selected)}
  end

  @impl true
  def handle_event("select_all", %{"checked" => checked}, socket) do
    selected = if checked == "true", do: Enum.map(socket.assigns.todos, & &1.id), else: []
    {:noreply, assign(socket, :selected_todos, selected)}
  end

  @impl true
  def handle_event("bulk_delete", _, socket) do
    ids = socket.assigns.selected_todos

    if length(ids) > 0 do
      Todos.bulk_delete_todos(ids, socket.assigns.current_user.id)
    end

    {:noreply, socket |> assign(:selected_todos, []) |> assign(:current_page, 1) |> load_todos()}
  end

  @impl true
  def handle_event("bulk_status", %{"status" => status}, socket) do
    user_id = socket.assigns.current_user.id

    Enum.each(socket.assigns.selected_todos, fn id ->
      Todos.update_todo(id, user_id, %{"status" => status})
    end)

    {:noreply, socket |> assign(:selected_todos, []) |> load_todos()}
  end

  # ─── Filters & Search ─────────────────────────────────────────────────────

  @impl true
  def handle_event("set_filter_status", %{"status" => status}, socket) do
    {:noreply,
     socket
     |> assign(:filter_status, status)
     |> assign(:current_page, 1)
     |> assign(:selected_todos, [])
     |> load_todos()}
  end

  @impl true
  def handle_event("set_search", %{"search" => search}, socket) do
    {:noreply, socket |> assign(:search, search) |> assign(:current_page, 1) |> load_todos()}
  end

  @impl true
  def handle_event("clear_search", _, socket) do
    {:noreply, socket |> assign(:search, "") |> assign(:current_page, 1) |> load_todos()}
  end

  @impl true
  def handle_event("set_filter_category", %{"category" => cat}, socket) do
    {:noreply,
     socket |> assign(:filter_category, cat) |> assign(:current_page, 1) |> load_todos()}
  end

  @impl true
  def handle_event("toggle_bookmarked", _, socket) do
    {:noreply,
     socket
     |> assign(:bookmarked_only, !socket.assigns.bookmarked_only)
     |> assign(:current_page, 1)
     |> load_todos()}
  end

  # ─── Pagination ────────────────────────────────────────────────────────────

  @impl true
  def handle_event("set_page", %{"page" => page}, socket) do
    {:noreply,
     socket
     |> assign(:current_page, String.to_integer(page))
     |> assign(:selected_todos, [])
     |> load_todos()}
  end

  @impl true
  def handle_event("set_per_page", %{"per_page" => v}, socket) do
    {:noreply,
     socket
     |> assign(:items_per_page, String.to_integer(v))
     |> assign(:current_page, 1)
     |> assign(:selected_todos, [])
     |> load_todos()}
  end

  # ─── Subtasks ─────────────────────────────────────────────────────────────

  @impl true
  def handle_event("open_subtasks", %{"id" => id}, socket) do
    todo = Todos.get_todo(String.to_integer(id), socket.assigns.current_user.id)
    {:noreply, socket |> assign(:subtask_todo, todo) |> assign(:new_subtask_title, "")}
  end

  @impl true
  def handle_event("close_subtasks", _, socket) do
    {:noreply, socket |> assign(:subtask_todo, nil) |> load_todos()}
  end

  @impl true
  def handle_event("add_subtask", %{"title" => title}, socket) do
    title = String.trim(title)

    if title != "" && socket.assigns.subtask_todo do
      Todos.create_subtask(socket.assigns.subtask_todo.id, socket.assigns.current_user.id, title)
      todo = Todos.get_todo(socket.assigns.subtask_todo.id, socket.assigns.current_user.id)
      {:noreply, socket |> assign(:subtask_todo, todo) |> assign(:new_subtask_title, "")}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("toggle_subtask", %{"id" => sid, "todo_id" => tid}, socket) do
    subtask = Enum.find(socket.assigns.subtask_todo.subtasks, &(to_string(&1.id) == sid))

    if subtask do
      Todos.update_subtask(
        String.to_integer(sid),
        String.to_integer(tid),
        socket.assigns.current_user.id,
        %{"completed" => !subtask.completed}
      )

      todo = Todos.get_todo(String.to_integer(tid), socket.assigns.current_user.id)
      {:noreply, assign(socket, :subtask_todo, todo)}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("delete_subtask", %{"id" => sid, "todo_id" => tid}, socket) do
    Todos.delete_subtask(
      String.to_integer(sid),
      String.to_integer(tid),
      socket.assigns.current_user.id
    )

    todo = Todos.get_todo(String.to_integer(tid), socket.assigns.current_user.id)
    {:noreply, assign(socket, :subtask_todo, todo)}
  end

  # ── Helpers ──────────────────────────────────────────────────────────────────

  defp status_label("in-progress"), do: "In Progress"
  defp status_label("on-hold"), do: "On Hold"
  defp status_label("completed"), do: "Completed"
  defp status_label(s), do: String.capitalize(to_string(s))

  defp status_badge_class("in-progress"), do: "badge-inprogress"
  defp status_badge_class("on-hold"), do: "badge-onhold"
  defp status_badge_class("completed"), do: "badge-completed"
  defp status_badge_class(_), do: "badge-inprogress"

  defp todo_status_str(todo), do: to_string(todo.status)

  defp subtask_progress(todo) do
    total = length(todo.subtasks)
    if total == 0, do: nil, else: {Enum.count(todo.subtasks, & &1.completed), total}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="app-wrapper" id="app-wrapper" phx-hook="SessionStore">

      <%!-- ─── Header ─────────────────────────────────────────────────────────── --%>
      <header class="app-header">
        <div class="header-inner">
          <span class="app-logo">TODOER</span>
          <div class="header-right">
            <div class="user-info">
              <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"/><circle cx="12" cy="7" r="4"/></svg>
              <span>{@current_user.name}</span>
            </div>
            <button phx-click="logout" class="logout-btn">
              <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"/><polyline points="16 17 21 12 16 7"/><line x1="21" y1="12" x2="9" y2="12"/></svg>
              Logout
            </button>
          </div>
        </div>
      </header>

      <%!-- ─── Main Content ─────────────────────────────────────────────────────── --%>
      <main class="app-main">
        <div class="page-title">
          <h1>Your Task Board</h1>
          <p>Stay organized, stay productive.</p>
        </div>

        <%!-- ─── Add Todo Input ──────────────────────────────────────────────────── --%>
        <div class="add-card">
          <form phx-submit="add_todo" class="add-row">
            <input name="title" type="text" value={@new_title} placeholder="What do you want to do?" class="add-input" autocomplete="off" />
            <button type="button" phx-click="toggle_extra" class="extra-toggle" title="More options">
              <%= if @show_extra, do: "▲", else: "▼" %>
            </button>
            <button type="submit" class="add-btn">
              <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><path d="M5 12h14"/><path d="m12 5 7 7-7 7"/></svg>
              Add
            </button>
          </form>

          <%= if @show_extra do %>
            <form phx-submit="add_todo" class="extra-fields">
              <input name="title" type="hidden" value="" />
              <input name="description" type="text" placeholder="Description (optional)" class="extra-input" />
              <div class="extra-row">
                <select name="category" class="extra-select">
                  <option value="">— Pick category —</option>
                  <%= for cat <- @categories do %>
                    <option value={cat}>{cat}</option>
                  <% end %>
                </select>
                <input name="custom_category" type="text" placeholder="Or type new category" class="extra-input flex-1" />
              </div>
            </form>
          <% end %>
        </div>

        <%!-- ─── Search & Filters ─────────────────────────────────────────────────── --%>
        <div class="filter-row">
          <div class="search-wrap">
            <svg class="search-icon" xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="11" cy="11" r="8"/><path d="m21 21-4.3-4.3"/></svg>
            <input
              type="text"
              value={@search}
              placeholder="Search tasks…"
              class="search-input"
              phx-keyup="set_search"
              phx-debounce="400"
              name="search"
            />
            <%= if @search != "" do %>
              <button phx-click="clear_search" class="search-clear">
                <svg xmlns="http://www.w3.org/2000/svg" width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M18 6 6 18"/><path d="m6 6 12 12"/></svg>
              </button>
            <% end %>
          </div>

          <select phx-change="set_filter_category" name="category" class="filter-select">
            <option value="">All Categories</option>
            <%= for cat <- @categories do %>
              <option value={cat} selected={@filter_category == cat}>{cat}</option>
            <% end %>
          </select>

          <button phx-click="toggle_bookmarked" class={"bookmark-btn #{if @bookmarked_only, do: "bookmark-btn--active"}"}>
            <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill={if @bookmarked_only, do: "currentColor", else: "none"} stroke="currentColor" stroke-width="2"><path d="m19 21-7-4-7 4V5a2 2 0 0 1 2-2h10a2 2 0 0 1 2 2v16z"/></svg>
            Bookmarks
          </button>
        </div>

        <%!-- ─── Action Bar ──────────────────────────────────────────────────────── --%>
        <div class="action-bar">
          <div class="action-left">
            <input
              type="checkbox"
              class="select-all-cb"
              checked={length(@selected_todos) == length(@todos) && length(@todos) > 0}
              phx-click="select_all"
              phx-value-checked={to_string(length(@selected_todos) != length(@todos) || length(@todos) == 0)}
            />
            <%= if length(@selected_todos) > 0 do %>
              <span class="selected-count">{length(@selected_todos)} selected</span>
              <select phx-change="bulk_status" name="status" class="bulk-select">
                <option value="">Set status…</option>
                <option value="in-progress">In Progress</option>
                <option value="on-hold">On Hold</option>
                <option value="completed">Completed</option>
              </select>
              <button phx-click="bulk_delete" class="bulk-delete-btn">
                <svg xmlns="http://www.w3.org/2000/svg" width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M3 6h18"/><path d="M19 6v14c0 1-1 2-2 2H7c-1 0-2-1-2-2V6"/><path d="M8 6V4c0-1 1-2 2-2h4c1 0 2 1 2 2v2"/></svg>
                Delete
              </button>
            <% end %>
          </div>
          <div class="status-filters">
            <%= for {label, val} <- [{"All", "all"}, {"In Progress", "in-progress"}, {"On Hold", "on-hold"}, {"Completed", "completed"}] do %>
              <button
                phx-click="set_filter_status"
                phx-value-status={val}
                class={"status-filter-btn #{if @filter_status == val, do: "status-filter-btn--active"}"}>
                {label}
              </button>
            <% end %>
          </div>
        </div>

        <%!-- ─── Todo List ──────────────────────────────────────────────────────── --%>
        <div class="todo-list">
          <%= if @todos == [] do %>
            <div class="empty-state">
              <svg xmlns="http://www.w3.org/2000/svg" width="40" height="40" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5"><path d="M9 11l3 3L22 4"/><path d="M21 12v7a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11"/></svg>
              <p>No tasks found. Add one above!</p>
            </div>
          <% else %>
            <%= for todo <- @todos do %>
              <div class="todo-item" id={"todo-#{todo.id}"}>
                <input
                  type="checkbox"
                  class="todo-cb"
                  checked={todo.id in @selected_todos}
                  phx-click="select_todo"
                  phx-value-id={todo.id}
                />

                <div class="todo-body">
                  <%= if @edit_todo_id == todo.id do %>
                    <form phx-submit="save_edit" class="edit-row">
                      <input name="title" type="text" value={@edit_title} class="edit-input" placeholder="Title" required />
                      <input name="description" type="text" value={@edit_description} class="edit-input" placeholder="Description" />
                      <input name="category" type="text" value={@edit_category} class="edit-input-sm" placeholder="Category" />
                      <button type="submit" class="save-btn">Save</button>
                      <button type="button" phx-click="cancel_edit" class="cancel-btn">Cancel</button>
                    </form>
                  <% else %>
                    <div class="todo-title-row">
                      <span class={"todo-title #{status_badge_class(todo_status_str(todo))}-title"}>
                        {todo.title}
                      </span>
                      <%= if todo.category do %>
                        <span class="category-chip">{todo.category}</span>
                      <% end %>
                    </div>
                    <%= if todo.description do %>
                      <p class="todo-desc">{todo.description}</p>
                    <% end %>
                    <%= case subtask_progress(todo) do %>
                      <% nil -> %> <%!-- no subtasks --%>
                      <% {done, total} -> %>
                        <div class="subtask-bar-wrap">
                          <div class="subtask-bar">
                            <div class="subtask-bar-fill" style={"width: #{round(done / total * 100)}%"}></div>
                          </div>
                          <span class="subtask-label">{done}/{total} subtasks</span>
                        </div>
                    <% end %>
                  <% end %>
                </div>

                <div class="todo-actions">
                  <%!-- Status badge + dropdown --%>
                  <div class="status-wrap">
                    <span class={"status-badge #{status_badge_class(todo_status_str(todo))}"}>
                      {status_label(todo_status_str(todo))}
                    </span>
                    <select
                      class="status-overlay"
                      phx-change="change_status"
                      phx-value-id={todo.id}
                      name="status">
                      <option value="in-progress"  selected={todo_status_str(todo) == "in-progress"}>In Progress</option>
                      <option value="on-hold"      selected={todo_status_str(todo) == "on-hold"}>On Hold</option>
                      <option value="completed"    selected={todo_status_str(todo) == "completed"}>Completed</option>
                    </select>
                  </div>

                  <div class="icon-actions">
                    <button phx-click="toggle_bookmark" phx-value-id={todo.id}
                      class={"icon-btn #{if todo.bookmarked, do: "icon-btn--bookmarked"}"} title="Bookmark">
                      <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill={if todo.bookmarked, do: "currentColor", else: "none"} stroke="currentColor" stroke-width="2"><path d="m19 21-7-4-7 4V5a2 2 0 0 1 2-2h10a2 2 0 0 1 2 2v16z"/></svg>
                    </button>

                    <button phx-click="open_subtasks" phx-value-id={todo.id}
                      class="icon-btn icon-btn--subtask" title="Subtasks">
                      <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polygon points="13 2 3 14 12 14 11 22 21 10 12 10 13 2"/></svg>
                      <%= if length(todo.subtasks) > 0 do %>
                        <span class="subtask-count">{length(todo.subtasks)}</span>
                      <% end %>
                    </button>

                    <button phx-click="start_edit" phx-value-id={todo.id}
                      class="icon-btn icon-btn--edit" title="Edit">
                      <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M17 3a2.85 2.83 0 1 1 4 4L7.5 20.5 2 22l1.5-5.5Z"/></svg>
                    </button>

                    <button phx-click="confirm_delete" phx-value-id={todo.id}
                      class="icon-btn icon-btn--delete" title="Delete">
                      <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M3 6h18"/><path d="M19 6v14c0 1-1 2-2 2H7c-1 0-2-1-2-2V6"/><path d="M8 6V4c0-1 1-2 2-2h4c1 0 2 1 2 2v2"/></svg>
                    </button>
                  </div>
                </div>
              </div>
            <% end %>
          <% end %>
        </div>

        <%!-- ─── Pagination ──────────────────────────────────────────────────────── --%>
        <%= if @pagination.total > 0 do %>
          <div class="pagination">
            <div class="pagination-left">
              <span class="pagination-info">
                Showing {((@pagination.page - 1) * @pagination.limit) + 1}–{min(@pagination.page * @pagination.limit, @pagination.total)} of {@pagination.total}
              </span>
              <select phx-change="set_per_page" name="per_page" class="per-page-select">
                <%= for n <- [5, 10, 20, 50] do %>
                  <option value={n} selected={@items_per_page == n}>{n} / page</option>
                <% end %>
              </select>
            </div>
            <div class="pagination-pages">
              <button
                phx-click="set_page" phx-value-page={@pagination.page - 1}
                disabled={@pagination.page <= 1}
                class="page-btn">
                ‹
              </button>
              <%= for p <- page_range(@pagination.page, @pagination.total_pages) do %>
                <%= if p == :ellipsis do %>
                  <span class="page-ellipsis">…</span>
                <% else %>
                  <button
                    phx-click="set_page" phx-value-page={p}
                    class={"page-btn #{if p == @pagination.page, do: "page-btn--active"}"}>
                    {p}
                  </button>
                <% end %>
              <% end %>
              <button
                phx-click="set_page" phx-value-page={@pagination.page + 1}
                disabled={@pagination.page >= @pagination.total_pages}
                class="page-btn">
                ›
              </button>
            </div>
          </div>
        <% end %>
      </main>

      <%!-- ─── Delete Modal ─────────────────────────────────────────────────────── --%>
      <%= if @delete_todo do %>
        <div class="modal-backdrop" phx-click="cancel_delete">
          <div class="modal-card" phx-click-away="cancel_delete">
            <div class="modal-icon">
              <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M3 6h18"/><path d="M19 6v14c0 1-1 2-2 2H7c-1 0-2-1-2-2V6"/><path d="M8 6V4c0-1 1-2 2-2h4c1 0 2 1 2 2v2"/></svg>
            </div>
            <h3 class="modal-title">Delete Task?</h3>
            <p class="modal-desc">
              "<strong>{@delete_todo.title}</strong>" will be permanently deleted.
            </p>
            <div class="modal-actions">
              <button phx-click="cancel_delete" class="modal-cancel">Cancel</button>
              <button phx-click="do_delete" class="modal-confirm">Delete</button>
            </div>
          </div>
        </div>
      <% end %>

      <%!-- ─── Subtask Panel ─────────────────────────────────────────────────────── --%>
      <%= if @subtask_todo do %>
        <div class="panel-backdrop" phx-click="close_subtasks">
          <div class="panel-card" phx-click-away="close_subtasks">
            <div class="panel-header">
              <h3 class="panel-title">Subtasks — {@subtask_todo.title}</h3>
              <button phx-click="close_subtasks" class="panel-close">
                <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M18 6 6 18"/><path d="m6 6 12 12"/></svg>
              </button>
            </div>

            <form phx-submit="add_subtask" class="subtask-add-row">
              <input name="title" type="text" value={@new_subtask_title} placeholder="Add a subtask…" class="subtask-input" autocomplete="off" />
              <button type="submit" class="subtask-add-btn">Add</button>
            </form>

            <div class="subtask-list">
              <%= if @subtask_todo.subtasks == [] do %>
                <p class="subtask-empty">No subtasks yet.</p>
              <% else %>
                <%= for sub <- @subtask_todo.subtasks do %>
                  <div class="subtask-item">
                    <input
                      type="checkbox"
                      checked={sub.completed}
                      phx-click="toggle_subtask"
                      phx-value-id={sub.id}
                      phx-value-todo_id={@subtask_todo.id}
                      class="subtask-cb"
                    />
                    <span class={"subtask-text #{if sub.completed, do: "subtask-text--done"}"}>{sub.title}</span>
                    <button
                      phx-click="delete_subtask"
                      phx-value-id={sub.id}
                      phx-value-todo_id={@subtask_todo.id}
                      class="subtask-del">
                      <svg xmlns="http://www.w3.org/2000/svg" width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M18 6 6 18"/><path d="m6 6 12 12"/></svg>
                    </button>
                  </div>
                <% end %>
              <% end %>
            </div>
          </div>
        </div>
      <% end %>

    </div>
    """
  end

  defp page_range(current, total) when total <= 7 do
    1..total |> Enum.to_list()
  end

  defp page_range(current, total) do
    cond do
      current <= 4 ->
        Enum.to_list(1..5) ++ [:ellipsis, total]

      current >= total - 3 ->
        [1, :ellipsis] ++ Enum.to_list((total - 4)..total)

      true ->
        [1, :ellipsis] ++ Enum.to_list((current - 1)..(current + 1)) ++ [:ellipsis, total]
    end
  end
end
