defmodule Ari.Schemas.Users.UserRole do
  use Ecto.Schema
  import Ecto.Changeset

  @schema_prefix "users"

  schema "user_roles" do
    field :user_id, :id  # Reference to the user
    field :role_id, :id  # Reference to the role

    timestamps()
  end

  def changeset(user_role, attrs) do
    user_role
    |> cast(attrs, [:user_id, :role_id])
    |> validate_required([:user_id, :role_id])
    |> unique_constraint(:user_id, name: :user_roles_user_id_role_id_index)  # Ensure unique user-role pairs
  end
end
