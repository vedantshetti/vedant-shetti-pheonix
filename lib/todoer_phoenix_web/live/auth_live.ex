defmodule TodoerPhoenixWeb.AuthLive do
  use TodoerPhoenixWeb, :live_view
  alias TodoerPhoenix.Accounts

  @impl true
  def mount(_params, _session, socket) do
    user = get_connect_params(socket)["user"]

    if connected?(socket) && !is_nil(user) && is_map(user) do
      {:ok, push_navigate(socket, to: "/")}
    else
      {:ok,
       socket
       |> assign(:form_error, nil)
       |> assign(:loading, false)}
    end
  end

  @impl true
  def handle_params(_params, _uri, socket) do
    {:noreply,
     socket
     |> assign(:form_error, nil)
     |> assign(:loading, false)}
  end

  @impl true
  def handle_event("login", %{"email" => email, "password" => password}, socket) do
    socket = assign(socket, :loading, true)

    case Accounts.authenticate_user(email, password) do
      {:ok, user} ->
        {:noreply,
         socket
         |> assign(:loading, false)
         |> push_event("save_user_session", %{
           user_id: user.id,
           user_name: user.name,
           user_email: user.email
         })
         |> push_navigate(to: "/")}

      {:error, _} ->
        {:noreply,
         socket
         |> assign(:loading, false)
         |> assign(:form_error, "Invalid email or password.")}
    end
  end

  @impl true
  def handle_event(
        "register",
        %{"name" => name, "email" => email, "password" => password},
        socket
      ) do
    socket = assign(socket, :loading, true)

    case Accounts.register_user(%{"name" => name, "email" => email, "password" => password}) do
      {:ok, user} ->
        {:noreply,
         socket
         |> assign(:loading, false)
         |> push_event("save_user_session", %{
           user_id: user.id,
           user_name: user.name,
           user_email: user.email
         })
         |> push_navigate(to: "/")}

      {:error, changeset} ->
        errors = format_errors(changeset)

        {:noreply,
         socket
         |> assign(:loading, false)
         |> assign(:form_error, errors)}
    end
  end

  defp format_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
    |> Enum.map(fn {field, msgs} -> "#{field}: #{Enum.join(msgs, ", ")}" end)
    |> Enum.join("; ")
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="auth-page" id="auth-page" phx-hook="SessionStore">
      <div class="auth-card">
        <div class="auth-logo">TODOER</div>

        <%= if @live_action == :login do %>
          <h2 class="auth-title">Welcome back</h2>
          <p class="auth-sub">Sign in to continue organizing your tasks</p>

          <%= if @form_error do %>
            <div class="auth-error">
              <svg
                xmlns="http://www.w3.org/2000/svg"
                width="15"
                height="15"
                viewBox="0 0 24 24"
                fill="none"
                stroke="currentColor"
                stroke-width="2"
                stroke-linecap="round"
                stroke-linejoin="round"
              >
                <circle cx="12" cy="12" r="10" /><line x1="12" y1="8" x2="12" y2="12" /><line
                  x1="12"
                  y1="16"
                  x2="12.01"
                  y2="16"
                />
              </svg>
              {@form_error}
            </div>
          <% end %>

          <form phx-submit="login" class="auth-form">
            <div class="field-group">
              <label for="login-email" class="field-label">Email</label>
              <div class="field-wrap">
                <svg
                  class="field-icon"
                  xmlns="http://www.w3.org/2000/svg"
                  width="15"
                  height="15"
                  viewBox="0 0 24 24"
                  fill="none"
                  stroke="currentColor"
                  stroke-width="2"
                >
                  <rect x="2" y="4" width="20" height="16" rx="2" /><path d="m22 7-8.97 5.7a1.94 1.94 0 0 1-2.06 0L2 7" />
                </svg>
                <input
                  id="login-email"
                  name="email"
                  type="email"
                  placeholder="you@example.com"
                  required
                  class="field-input"
                />
              </div>
            </div>
            <div class="field-group">
              <label for="login-password" class="field-label">Password</label>
              <div class="field-wrap">
                <svg
                  class="field-icon"
                  xmlns="http://www.w3.org/2000/svg"
                  width="15"
                  height="15"
                  viewBox="0 0 24 24"
                  fill="none"
                  stroke="currentColor"
                  stroke-width="2"
                >
                  <rect x="3" y="11" width="18" height="11" rx="2" ry="2" /><path d="M7 11V7a5 5 0 0 1 10 0v4" />
                </svg>
                <input
                  id="login-password"
                  name="password"
                  type="password"
                  placeholder="password123"
                  required
                  class="field-input"
                />
              </div>
            </div>
            <button type="submit" disabled={@loading} class="auth-btn">
              <%= if @loading do %>
                <svg
                  class="spin-icon"
                  xmlns="http://www.w3.org/2000/svg"
                  width="16"
                  height="16"
                  viewBox="0 0 24 24"
                  fill="none"
                  stroke="currentColor"
                  stroke-width="2"
                >
                  <path d="M21 12a9 9 0 1 1-6.219-8.56" />
                </svg>
                Signing in...
              <% else %>
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  width="16"
                  height="16"
                  viewBox="0 0 24 24"
                  fill="none"
                  stroke="currentColor"
                  stroke-width="2"
                >
                  <path d="M5 12h14" /><path d="m12 5 7 7-7 7" />
                </svg>
                Sign In
              <% end %>
            </button>
          </form>

          <p class="auth-switch">
            Don't have an account? <.link navigate="/register" class="auth-link">Create one</.link>
          </p>
        <% else %>
          <h2 class="auth-title">Create account</h2>
          <p class="auth-sub">Start organizing your tasks today</p>

          <%= if @form_error do %>
            <div class="auth-error">
              <svg
                xmlns="http://www.w3.org/2000/svg"
                width="15"
                height="15"
                viewBox="0 0 24 24"
                fill="none"
                stroke="currentColor"
                stroke-width="2"
              >
                <circle cx="12" cy="12" r="10" /><line x1="12" y1="8" x2="12" y2="12" /><line
                  x1="12"
                  y1="16"
                  x2="12.01"
                  y2="16"
                />
              </svg>
              {@form_error}
            </div>
          <% end %>

          <form phx-submit="register" class="auth-form">
            <div class="field-group">
              <label for="reg-name" class="field-label">Name</label>
              <div class="field-wrap">
                <svg
                  class="field-icon"
                  xmlns="http://www.w3.org/2000/svg"
                  width="15"
                  height="15"
                  viewBox="0 0 24 24"
                  fill="none"
                  stroke="currentColor"
                  stroke-width="2"
                >
                  <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2" /><circle cx="12" cy="7" r="4" />
                </svg>
                <input
                  id="reg-name"
                  name="name"
                  type="text"
                  placeholder="Your name"
                  required
                  class="field-input"
                />
              </div>
            </div>
            <div class="field-group">
              <label for="reg-email" class="field-label">Email</label>
              <div class="field-wrap">
                <svg
                  class="field-icon"
                  xmlns="http://www.w3.org/2000/svg"
                  width="15"
                  height="15"
                  viewBox="0 0 24 24"
                  fill="none"
                  stroke="currentColor"
                  stroke-width="2"
                >
                  <rect x="2" y="4" width="20" height="16" rx="2" /><path d="m22 7-8.97 5.7a1.94 1.94 0 0 1-2.06 0L2 7" />
                </svg>
                <input
                  id="reg-email"
                  name="email"
                  type="email"
                  placeholder="you@example.com"
                  required
                  class="field-input"
                />
              </div>
            </div>
            <div class="field-group">
              <label for="reg-password" class="field-label">Password</label>
              <div class="field-wrap">
                <svg
                  class="field-icon"
                  xmlns="http://www.w3.org/2000/svg"
                  width="15"
                  height="15"
                  viewBox="0 0 24 24"
                  fill="none"
                  stroke="currentColor"
                  stroke-width="2"
                >
                  <rect x="3" y="11" width="18" height="11" rx="2" ry="2" /><path d="M7 11V7a5 5 0 0 1 10 0v4" />
                </svg>
                <input
                  id="reg-password"
                  name="password"
                  type="password"
                  placeholder="min 6 characters"
                  required
                  class="field-input"
                />
              </div>
            </div>
            <button type="submit" disabled={@loading} class="auth-btn">
              <%= if @loading do %>
                <svg
                  class="spin-icon"
                  xmlns="http://www.w3.org/2000/svg"
                  width="16"
                  height="16"
                  viewBox="0 0 24 24"
                  fill="none"
                  stroke="currentColor"
                  stroke-width="2"
                >
                  <path d="M21 12a9 9 0 1 1-6.219-8.56" />
                </svg>
                Creating...
              <% else %>
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  width="16"
                  height="16"
                  viewBox="0 0 24 24"
                  fill="none"
                  stroke="currentColor"
                  stroke-width="2"
                >
                  <path d="M5 12h14" /><path d="m12 5 7 7-7 7" />
                </svg>
                Create Account
              <% end %>
            </button>
          </form>

          <p class="auth-switch">
            Already have an account? <.link navigate="/login" class="auth-link">Sign in</.link>
          </p>
        <% end %>
      </div>
    </div>
    """
  end
end
