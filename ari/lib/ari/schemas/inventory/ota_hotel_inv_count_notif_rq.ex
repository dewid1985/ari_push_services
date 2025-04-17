defmodule Ari.Schemas.Inventory.OtaHotelInvCountNotifRQ do
  use Ecto.Schema
  import Ecto.Changeset

  @schema_prefix "inventory"

  schema "ota_hotel_inv_count_notif_rq" do
    field :time_stamp, :utc_datetime_usec
    field :version, :string
    field :message_content_code, :string
    field :outside_id, :string
    field :message_id, :integer
    field :customer_code, :string
    field :active, :boolean, default: true

    # Связь один к одному с Inventories
    has_one :inventories, Ari.Schemas.Inventory.Inventories

    timestamps()
  end

  def changeset(notif, attrs) do
    notif
    |> cast(attrs, [:time_stamp, :version, :message_content_code, :outside_id, :message_id, :customer_code, :active])
    |> validate_required([:time_stamp, :version])
    |> cast_assoc(:inventories)
  end
end