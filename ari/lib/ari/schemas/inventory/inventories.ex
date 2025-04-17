defmodule Ari.Schemas.Inventory.Inventories do
  use Ecto.Schema
  import Ecto.Changeset

  @schema_prefix "inventory"
  schema "inventories" do
    field :hotel_code, :string

    # Внешний ключ на уведомление
    belongs_to :ota_hotel_inv_count_notif_rq, Ari.Schemas.Inventory.OTAHotelInvCountNotifRq

    # Список элементов Inventory (ключ "inventory" соответствует вашему маппингу)
    has_many :inventory, Ari.Schemas.Inventory.Inventory

    # Связь один к одному с таблицей UniqueId
    has_one :unique_id, Ari.Schemas.Inventory.UniqueId

    timestamps()
  end

  def changeset(inventories, attrs) do
    inventories
    |> cast(attrs, [:hotel_code])
    |> validate_required([:hotel_code])
    |> cast_assoc(:unique_id)
    |> cast_assoc(:inventory)
  end
end