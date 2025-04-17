defmodule Ari.Schemas.Users.Role do
  use Ecto.Schema
  import Ecto.Changeset

  @schema_prefix "users"

  schema "roles" do
    field :name, :string
    field :parent_role_id, :id  # Reference to parent role

    timestamps()
  end

  def changeset(role, attrs) do
    role
    |> cast(attrs, [:name, :parent_role_id])
    |> validate_required([:name])
    |> unique_constraint(:name)
  end
end
