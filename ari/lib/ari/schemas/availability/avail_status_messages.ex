defmodule Ari.Schemas.Availability.AvailStatusMessages do
  use Ecto.Schema
  import Ecto.Changeset

  @schema_prefix "availability"

  schema "avail_status_messages" do
    field :hotel_code, :string

    belongs_to :ota_hotel_avail_notif_rq, Ari.Schemas.Availability.OtaHotelAvailNotifRq

    has_many :avail_status_message, Ari.Schemas.Availability.AvailStatusMessage

    timestamps()
  end

  def changeset(avail_status_messages, attrs) do
    avail_status_messages
    |> cast(attrs, [:hotel_code])
    |> validate_required([:hotel_code], message: "361|Invalid Hotel")
    |> validate_length(:hotel_code, min: 4, max: 12, message: "361|Invalid Hotel")
    |> validate_format(:hotel_code, ~r/^[a-zA-Z0-9]+$/, message: "361|Invalid Hotel")
    |> cast_assoc(:avail_status_message, required: true)
  end
end