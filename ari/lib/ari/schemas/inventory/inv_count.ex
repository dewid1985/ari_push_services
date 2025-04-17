defmodule Ari.Schemas.Inventory.InvCount do
  use Ecto.Schema
  import Ecto.Changeset

  @schema_prefix "inventory"
  schema "inv_count" do
    field :count_type, :string
    field :count, :integer

    # Внешний ключ на InvCounts
    belongs_to :inv_counts, Ari.Schemas.Inventory.InvCounts

    timestamps()
  end

  def changeset(inv_count, attrs) do
    inv_count
    |> cast(attrs, [:count_type, :count])
    |> validate_required([:count_type, :count])
  end
end