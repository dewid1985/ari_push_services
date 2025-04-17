defmodule Ari.Schemas.Inventory.InvCounts do
  use Ecto.Schema
  import Ecto.Changeset

  @schema_prefix "inventory"
  schema "inv_counts" do
    # Внешний ключ на Inventory
    belongs_to :inventory, Ari.Schemas.Inventory.Inventory

    # Список отдельных записей InvCount
    has_many :inv_count, Ari.Schemas.Inventory.InvCount

    timestamps()
  end

  def changeset(inv_counts, attrs) do
    inv_counts
    |> cast(attrs, [])
    |> cast_assoc(:inv_count)
  end
end