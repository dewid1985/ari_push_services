defmodule Ari.Schemas.Inventory.Inventory do
  use Ecto.Schema
  import Ecto.Changeset

  @schema_prefix "inventory"
  schema "inventory" do
    # Внешний ключ на Inventories
    belongs_to :inventories, Ari.Schemas.Inventory.Inventories

    # Элемент StatusApplicationControl для данного Inventory
    has_one :status_application_control, Ari.Schemas.Inventory.StatusApplicationControl

    # Ссылка на InvCounts (каждый Inventory содержит данные InvCounts)
    has_one :inv_counts, Ari.Schemas.Inventory.InvCounts

    timestamps()
  end

  def changeset(inventory, attrs) do
    inventory
    |> cast(attrs, [])
    |> cast_assoc(:status_application_control)
    |> cast_assoc(:inv_counts)
  end
end