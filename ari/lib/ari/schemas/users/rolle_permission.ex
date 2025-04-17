defmodule Ari.Schemas.Users.RolePermission do
  use Ecto.Schema
  import Ecto.Changeset

  @schema_prefix "users"

  schema "role_permissions" do
    field :role_id, :id  # Reference to the role
    field :permission_id, :id  # Reference to the permission

    timestamps()
  end

  def changeset(role_permission, attrs) do
    role_permission
    |> cast(attrs, [:role_id, :permission_id])
    |> validate_required([:role_id, :permission_id])
    |> unique_constraint(:role_id, name: :role_permissions_role_id_permission_id_index)  # Ensure unique role-permission pairs
  end
end
