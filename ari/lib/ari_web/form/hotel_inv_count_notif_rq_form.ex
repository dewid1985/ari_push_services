defmodule AriWeb.Form.HotelInvCountNotifRqForm do
  use Ecto.Schema
  alias Ari.Schemas.Inventory.UpdateInventory

  def changeset(%UpdateInventory{} = inventory_massage, attrs) do
    UpdateInventory.changeset(inventory_massage, attrs)
  end
end