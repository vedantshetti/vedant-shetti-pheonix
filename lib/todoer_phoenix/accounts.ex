defmodule TodoerPhoenix.Accounts do
  @moduledoc """
  The Accounts context — handles user registration and authentication.
  Mirrors the Node.js authController.js logic.
  """
  import Ecto.Query
  alias TodoerPhoenix.Repo
  alias TodoerPhoenix.Accounts.User

  @doc "Register a new user — returns {:ok, user} or {:error, changeset}"
  def register_user(attrs) do
    %User{}
    |> User.registration_changeset(attrs)
    |> Repo.insert()
  end

  @doc "Authenticate user by email/password — returns {:ok, user} or {:error, reason}"
  def authenticate_user(email, password) do
    user = Repo.get_by(User, email: String.downcase(String.trim(email)))

    cond do
      is_nil(user) ->
        Bcrypt.no_user_verify()
        {:error, :invalid_credentials}

      Bcrypt.verify_pass(password, user.password) ->
        {:ok, user}

      true ->
        {:error, :invalid_credentials}
    end
  end

  @doc "Get a user by ID"
  def get_user(id), do: Repo.get(User, id)
end
