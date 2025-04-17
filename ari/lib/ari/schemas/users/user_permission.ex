defmodule Ari.Schemas.Users.UserPermission do
  use Ecto.Schema
  import Ecto.Changeset

  @schema_prefix "users"

  schema "user_permissions" do
    field :user_id, :id  # Reference to the user
    field :permission_id, :id  # Reference to the permission

    timestamps()
  end

  def changeset(user_permission, attrs) do
    user_permission
    |> cast(attrs, [:user_id, :permission_id])
    |> validate_required([:user_id, :permission_id])
    |> unique_constraint(:user_id, name: :user_permissions_user_id_permission_id_index)  # Ensure unique user-permission pairs
  end
end
