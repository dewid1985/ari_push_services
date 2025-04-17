defmodule Ari.Schemas.Users.Resource do
  use Ecto.Schema
  import Ecto.Changeset

  @schema_prefix "users"

  schema "resources" do
    field :name, :string
    field :description, :string
    field :url, :string

    timestamps()
  end

  def changeset(resource, attrs) do
    resource
    |> cast(attrs, [:name, :description, :url])
    |> validate_required([:name, :url])
    |> unique_constraint(:name)
  end
end
