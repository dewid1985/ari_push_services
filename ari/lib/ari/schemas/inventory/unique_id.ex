defmodule Ari.Schemas.Inventory.UniqueId do
  use Ecto.Schema
  import Ecto.Changeset

  @schema_prefix "inventory"

  @moduledoc """
  Represents the UniqueID element associated with an Inventories record.
  Stores the unique identifier value and its type attribute.
  """

  schema "unique_id" do
    field :code, :string
    field :type, :string

    # Belongs to an Inventories record.
    belongs_to :inventories, Ari.Schemas.Inventory.Inventories

    timestamps()
  end

  def changeset(unique_id, attrs) do
    unique_id
    |> cast(attrs, [:type, :code])  # Cast only the `type` and `code` fields from the incoming attributes.
    |> validate_required([:type])  # Ensure both fields are present in the changeset.
  end
end
