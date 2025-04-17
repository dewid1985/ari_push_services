defmodule Ari.Schemas.Users.Permission do
  use Ecto.Schema
  import Ecto.Changeset

  @schema_prefix "users"

  schema "permissions" do
    field :action, :string
    field :resource_id, :id  # Reference to the resource

    timestamps()
  end

  def changeset(permission, attrs) do
    permission
    |> cast(attrs, [:action, :resource_id])
    |> validate_required([:action, :resource_id])
    |> unique_constraint(:action, name: :permissions_action_resource_id_index)  # Ensure unique action-resource combinations
  end
end
