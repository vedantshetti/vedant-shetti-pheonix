defmodule TodoerPhoenix.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  @derive {Jason.Encoder, only: [:id, :name, :email]}

  schema "users" do
    field(:name, :string)
    field(:email, :string)
    field(:password, :string)

    has_many(:todos, TodoerPhoenix.Todos.Todo)

    timestamps(type: :naive_datetime, inserted_at: :created_at, updated_at: false)
  end

  def registration_changeset(user, attrs) do
    user
    |> cast(attrs, [:name, :email, :password])
    |> validate_required([:name, :email, :password])
    |> validate_format(:email, ~r/@/)
    |> validate_length(:password, min: 6)
    |> unique_constraint(:email, name: :users_email_key, message: "has already been taken")
    |> put_password_hash()
  end

  defp put_password_hash(%Ecto.Changeset{valid?: true, changes: %{password: pwd}} = changeset) do
    change(changeset, password: Bcrypt.hash_pwd_salt(pwd))
  end

  defp put_password_hash(changeset), do: changeset
end
